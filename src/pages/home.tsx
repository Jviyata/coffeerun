import React, { useState, useRef } from "react";
import { Link } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";

const fadeUp = { hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } };
const inView  = { hidden: { opacity: 0, y: 28 }, visible: { opacity: 1, y: 0, transition: { duration: 0.7, ease: [0.22, 1, 0.36, 1] } } };

// ─── Helpers ─────────────────────────────────────────────────────────────────

function hashColor(name: string): string {
  const palette = ["#C9826A", "#7AAF72", "#7A9BD9", "#B87AAF", "#D4AD5C", "#72B3BD", "#A687CC", "#C97A82"];
  let h = 5381;
  for (let i = 0; i < name.length; i++) h = ((h << 5) + h + name.charCodeAt(i)) >>> 0;
  return palette[h % palette.length];
}

function initials(name: string): string {
  const p = name.trim().split(/\s+/);
  if (p.length >= 2) return (p[0][0] + p[1][0]).toUpperCase();
  return name.slice(0, 2).toUpperCase();
}

// ─── Shared mini-components ───────────────────────────────────────────────────

function BreathingDot({ color }: { color: string }) {
  return (
    <span style={{ position: "relative", display: "inline-flex", alignItems: "center", justifyContent: "center", width: 16, height: 16, flexShrink: 0 }}>
      <span style={{ position: "absolute", width: 16, height: 16, borderRadius: "50%", background: color, opacity: 0.3, animation: "breathe 2s ease-out infinite" }} />
      <span style={{ width: 7, height: 7, borderRadius: "50%", background: color, flexShrink: 0 }} />
    </span>
  );
}

function Avatar({ name, online, size = 32 }: { name: string; online?: boolean; size?: number }) {
  const color = hashColor(name);
  return (
    <span style={{ position: "relative", display: "inline-flex", flexShrink: 0 }}>
      <span style={{
        width: size, height: size, borderRadius: "50%",
        background: color,
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: size * 0.36, fontWeight: 600, color: "rgba(255,255,255,0.92)",
        letterSpacing: "-0.02em", flexShrink: 0,
      }}>
        {initials(name)}
      </span>
      {online && (
        <span style={{ position: "absolute", bottom: 0, right: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <span style={{ position: "absolute", width: size * 0.44, height: size * 0.44, borderRadius: "50%", background: "#4CAF6A44", animation: "breathe 2s ease-out infinite" }} />
          <span style={{ width: size * 0.28, height: size * 0.28, borderRadius: "50%", background: "#4CAF6A", border: "1.5px solid #19100A", position: "relative" }} />
        </span>
      )}
    </span>
  );
}

// ─── Types ────────────────────────────────────────────────────────────────────

type Status = "available" | "notAvailable" | "goingNow" | "joining";
interface Run {
  id: string;
  organizer: { id: string; name: string; note?: string; minsUntil?: number; startedAgo?: string };
  joiners: { id: string; name: string }[];
}

// ─── App Demo ─────────────────────────────────────────────────────────────────

function AppDemo() {
  const ME = "you";
  const [status,         setStatus]         = useState<Status>("available");
  const [showRunOptions, setShowRunOptions]  = useState(false);
  const [showNoteField,  setShowNoteField]   = useState(false);
  const [noteDraft,      setNoteDraft]       = useState("");
  const [savedNote,      setSavedNote]       = useState("");
  const [isCaffeinated,  setIsCaffeinated]   = useState(false);
  const [toastMsg,       setToastMsg]        = useState<string | null>(null);
  const [audienceChip,   setAudienceChip]    = useState<string>("everyone");
  const [ownRun,         setOwnRun]          = useState<Run | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const [nearbyRuns, setNearbyRuns] = useState<Run[]>([
    { id: "r1", organizer: { id: "maya", name: "Maya Chen", note: "Kitchen", minsUntil: 2 }, joiners: [{ id: "jake", name: "Jake Torres" }] },
  ]);

  const showToast = (msg: string) => {
    if (toastTimer.current) clearTimeout(toastTimer.current);
    setToastMsg(msg);
    toastTimer.current = setTimeout(() => setToastMsg(null), 2500);
  };

  const allRuns: Run[] = [...(ownRun ? [ownRun] : []), ...nearbyRuns];
  const myRunId = ownRun?.id;
  const amInRun = (r: Run) => r.id === myRunId || r.joiners.some(j => j.id === ME);

  const doSetStatus = (s: Status) => {
    setStatus(s);
    setShowRunOptions(false);
    if (s === "available" || s === "notAvailable") setOwnRun(null);
  };

  const startRun = (mins: number) => {
    setOwnRun({ id: "own", organizer: { id: ME, name: "You", note: savedNote || undefined, minsUntil: mins > 0 ? mins : undefined, startedAgo: mins === 0 ? "just now" : undefined }, joiners: [] });
    setStatus("goingNow");
    setShowRunOptions(false);
    const scope = audienceChip === "everyone" ? " · everyone nearby" : ` · ${audienceChip} crew`;
    showToast(mins > 0 ? `Run scheduled in ${mins} min${scope}` : `Run started${scope}`);
  };

  const joinRun = (r: Run) => {
    setNearbyRuns(prev => prev.map(x => x.id === r.id ? { ...x, joiners: [...x.joiners, { id: ME, name: "You" }] } : x));
    setStatus("joining");
    showToast("Joined the run");
  };

  const leaveRun = (r: Run) => {
    if (r.id === "own") { setOwnRun(null); doSetStatus("available"); }
    else { setNearbyRuns(prev => prev.map(x => x.id === r.id ? { ...x, joiners: x.joiners.filter(j => j.id !== ME) } : x)); doSetStatus("available"); }
  };

  const logCoffee = () => { showToast("Coffee logged — enjoy!"); doSetStatus("available"); };

  const saveNote = () => {
    setSavedNote(noteDraft);
    if (ownRun) setOwnRun(r => r ? { ...r, organizer: { ...r.organizer, note: noteDraft || undefined } } : r);
    setShowNoteField(false);
  };

  const heroHeadline = () => {
    if (status === "available")    return "Open for a quick break";
    if (status === "notAvailable") return "Heads down right now";
    if (status === "goingNow") {
      const joiners = ownRun?.joiners ?? [];
      if (joiners.length === 1) return `Brewing with ${joiners[0].name}`;
      if (joiners.length > 1)  return `Brewing with ${joiners[0].name} + ${joiners.length - 1}`;
      return "Brewing a Brwup";
    }
    if (status === "joining") {
      const r = nearbyRuns.find(x => x.joiners.some(j => j.id === ME));
      return r ? `Joined ${r.organizer.name}'s run` : "Joined a Brwup";
    }
    return "Open for a quick break";
  };
  const heroSubtitle = () => {
    if (status === "available")    return "Let nearby people know you're up for it.";
    if (status === "notAvailable") return "You won't show up to your crew.";
    if (status === "goingNow") {
      const joiners = ownRun?.joiners ?? [];
      if (joiners.length > 0) return `${joiners.length === 1 ? "They're" : `${joiners.length} are`} in. Anyone else?`;
      if (ownRun?.organizer.minsUntil) return `Starting in ${ownRun.organizer.minsUntil} min — your crew can join.`;
      return "Your crew can join for the next 30 minutes.";
    }
    if (status === "joining") {
      const r = nearbyRuns.find(x => x.joiners.some(j => j.id === ME));
      if (r?.organizer.note) return `Meet at ${r.organizer.note}`;
      if (r?.organizer.minsUntil) return `Leaving in ${r.organizer.minsUntil} min.`;
      return "You're in.";
    }
    return "Let nearby people know you're up for it.";
  };
  const heroDotColor = () => {
    if (status === "available")    return "#4CAF6A";
    if (status === "notAvailable") return "#666";
    return "#E8A040";
  };

  const activityHeadline = (r: Run) => {
    const isOwn = r.id === "own";
    if (isOwn) {
      if (r.joiners.length === 1) return `Your run · ${r.joiners[0].name} joined`;
      if (r.joiners.length > 1)  return `Your run · ${r.joiners[0].name} + ${r.joiners.length - 1} joined`;
      return "Your run · waiting for someone";
    }
    if (amInRun(r)) return `You joined ${r.organizer.name}'s run`;
    return `${r.organizer.name} is heading out`;
  };
  const timingPhrase = (r: Run) => {
    if (r.organizer.minsUntil && r.organizer.minsUntil > 0) return `Leaving in ${r.organizer.minsUntil} min`;
    return r.organizer.startedAgo ? `Started ${r.organizer.startedAgo}` : "Just now";
  };

  // Palette
  const BG     = "#19100A";
  const CARD   = "rgba(255,255,255,0.055)";
  const BORDER = "rgba(255,255,255,0.07)";
  const T1     = "rgba(255,255,255,0.88)";
  const T2     = "rgba(255,255,255,0.42)";
  const T3     = "rgba(255,255,255,0.2)";
  const AMBER  = "#C47A2B";
  const AMBERBG= "rgba(196,122,43,0.12)";
  const SF     = { fontFamily: "-apple-system,'SF Pro Text','DM Sans',sans-serif" };

  const utilRow = (title: string, subtitle: string, accent: string, trailing: React.ReactNode, action: () => void) => (
    <button
      onClick={action}
      style={{ width: "100%", display: "flex", alignItems: "center", gap: 10, padding: "9px 12px", background: "transparent", border: "none", cursor: "pointer", textAlign: "left" }}
      onMouseEnter={e => (e.currentTarget.style.background = "rgba(255,255,255,0.035)")}
      onMouseLeave={e => (e.currentTarget.style.background = "transparent")}
    >
      <span style={{ width: 3, height: 28, borderRadius: 2, background: accent, flexShrink: 0 }} />
      <span style={{ flex: 1, minWidth: 0 }}>
        <span style={{ display: "block", fontSize: 12, fontWeight: 600, color: T1 }}>{title}</span>
        <span style={{ display: "block", fontSize: 11, color: T2, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{subtitle}</span>
      </span>
      {trailing}
    </button>
  );

  const navRow = (title: string, red?: boolean) => (
    <button
      style={{ width: "100%", display: "flex", alignItems: "center", gap: 10, padding: "9px 12px", background: "transparent", border: "none", cursor: "pointer" }}
      onMouseEnter={e => (e.currentTarget.style.background = "rgba(255,255,255,0.035)")}
      onMouseLeave={e => (e.currentTarget.style.background = "transparent")}
    >
      <span style={{ width: 3, height: 20, borderRadius: 2, background: red ? "#FF453A22" : T3, flexShrink: 0 }} />
      <span style={{ flex: 1, fontSize: 12, fontWeight: 500, color: red ? "#FF453A" : T1, textAlign: "left" }}>{title}</span>
      {!red && <span style={{ fontSize: 11, color: T3 }}>›</span>}
    </button>
  );

  const steps = [
    { title: "Status card", desc: "The top card reflects your live status — it changes the moment you tap a button below it." },
    { title: "Three action buttons", desc: "Brwup = you're heading out. Available = open but not leading. Heads Down = DND. Tapping Brwup reveals timing options." },
    { title: "Run timing panel", desc: "Choose Now, In 5 min, or In 15 min. The run auto-expires after 30 minutes." },
    { title: "What's happening nearby", desc: "Real-time list of who's brewing. Join any run instantly — the organizer sees your name appear on their card." },
    { title: "Caffeinated Mode", desc: "Prevents your Mac from sleeping while a run is live. Snaps off the moment the run ends." },
    { title: "Add a note", desc: "Type a location or timing hint. It appears below your name on everyone else's activity card." },
  ];

  return (
    <div style={{ display: "flex", flexDirection: "row", alignItems: "flex-start", gap: 48, flexWrap: "wrap", width: "100%", maxWidth: 900, margin: "0 auto" }}>

      {/* ── The App ── */}
      <div style={{ width: 310, flexShrink: 0 }}>
        <div style={{
          ...SF, background: BG, borderRadius: 14, overflow: "hidden",
          boxShadow: "0 24px 80px rgba(0,0,0,0.75), 0 0 0 0.5px rgba(255,255,255,0.08)",
          maxHeight: 700, overflowY: "auto",
        }}>

          {/* Toast */}
          <AnimatePresence>
            {toastMsg && (
              <motion.div
                initial={{ y: -36, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: -36, opacity: 0 }}
                transition={{ type: "spring", stiffness: 420, damping: 32 }}
                style={{ position: "sticky", top: 0, zIndex: 99, padding: "6px 10px" }}
              >
                <div style={{ background: "#3D6B4E", borderRadius: 8, padding: "8px 12px", fontSize: 12, fontWeight: 500, color: "white" }}>
                  {toastMsg}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          <div style={{ padding: "10px 12px 14px" }}>

            {/* Header */}
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 10 }}>
              <span style={{ fontSize: 14, fontWeight: 700, color: T1, letterSpacing: "-0.01em" }}>Brwup</span>
              <button style={{ background: "none", border: `0.5px solid ${BORDER}`, borderRadius: 6, cursor: "pointer", color: T2, fontSize: 10, fontWeight: 500, padding: "3px 8px", letterSpacing: "0.04em" }}>Settings</button>
            </div>

            {/* Buzzes blocked banner */}
            <div style={{ background: AMBERBG, border: `0.5px solid rgba(196,122,43,0.2)`, borderRadius: 10, padding: "10px 12px", marginBottom: 10 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: AMBER, marginBottom: 2 }}>Buzzes are blocked</div>
              <div style={{ fontSize: 11, color: "rgba(196,122,43,0.6)", lineHeight: 1.5 }}>Enable in System Settings to hear when someone starts a run.</div>
              <button style={{ fontSize: 11, fontWeight: 500, color: "#5BA4CF", background: "none", border: "none", cursor: "pointer", padding: 0, marginTop: 4 }}>Open Settings</button>
            </div>

            {/* Hero status card */}
            <div style={{ background: CARD, border: `0.5px solid ${BORDER}`, borderRadius: 12, padding: "12px 14px", marginBottom: 10, display: "flex", gap: 12, alignItems: "center" }}>
              <img src="/cup.png" alt="" style={{ width: 72, height: 52, objectFit: "cover", objectPosition: "center", flexShrink: 0, borderRadius: 6, opacity: 0.92 }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "flex-start", gap: 6, marginBottom: 4 }}>
                  <span style={{ fontSize: 13, fontWeight: 600, color: T1, flex: 1, lineHeight: 1.3 }}>{heroHeadline()}</span>
                  <BreathingDot color={heroDotColor()} />
                </div>
                <div style={{ fontSize: 11, color: T2, lineHeight: 1.45 }}>{heroSubtitle()}</div>
              </div>
            </div>

            {/* Stats row */}
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 10 }}>
              {[
                { label: "Coffees today", sub: "nearby", val: 3, note: "2 in your crew", noteColor: "#4CAF6A" },
                { label: "Coffees sparked", sub: "by you this week", val: 7, note: "3 day streak", noteColor: "#E8A040" },
              ].map((s, i) => (
                <div key={i} style={{ background: CARD, border: `0.5px solid ${BORDER}`, borderRadius: 10, padding: "10px 12px" }}>
                  <span style={{ fontSize: 28, fontWeight: 800, color: T1, lineHeight: 1, display: "block", marginBottom: 4 }}>{s.val}</span>
                  <div style={{ fontSize: 11, fontWeight: 500, color: T2, lineHeight: 1.3 }}>{s.label}<br /><span style={{ color: T3 }}>{s.sub}</span></div>
                  <div style={{ fontSize: 10, fontWeight: 500, color: s.noteColor, marginTop: 4 }}>{s.note}</div>
                </div>
              ))}
            </div>

            {/* Audience filter */}
            <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 10, padding: "0 2px" }}>
              <span style={{ fontSize: 11, color: T3 }}>Showing</span>
              <select
                value={audienceChip}
                onChange={e => setAudienceChip(e.target.value)}
                style={{ fontSize: 12, fontWeight: 500, color: T1, background: "transparent", border: "none", outline: "none", cursor: "pointer", ...SF }}
              >
                <option value="everyone" style={{ background: "#2A1A0E" }}>Everyone nearby</option>
                <option value="design"   style={{ background: "#2A1A0E" }}>Design crew</option>
                <option value="eng"      style={{ background: "#2A1A0E" }}>Eng crew</option>
              </select>
              <span style={{ marginLeft: "auto", fontSize: 11, fontWeight: 600, color: T1 }}>{nearbyRuns.length + 2}</span>
            </div>

            {/* Three action buttons */}
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 7, marginBottom: 10 }}>
              {[
                { key: "goingNow",     label: "Brwup",      sub: "Start a run",    bg: "rgba(196,122,43,0.9)",  fg: "#1A0E06" },
                { key: "available",    label: "Available",  sub: "Open for it",    bg: "rgba(76,112,67,0.9)",   fg: "#ffffff" },
                { key: "notAvailable", label: "Heads Down", sub: "Not available",  bg: "rgba(48,48,48,0.9)",    fg: "rgba(255,255,255,0.8)" },
              ].map(tab => {
                const sel = status === tab.key;
                return (
                  <button
                    key={tab.key}
                    onClick={() => {
                      if (tab.key === "goingNow") { setShowRunOptions(v => !v); setShowNoteField(false); }
                      else doSetStatus(tab.key as Status);
                    }}
                    style={{
                      background: tab.bg,
                      border: sel ? "2px solid rgba(255,255,255,0.5)" : "2px solid transparent",
                      borderRadius: 10, padding: "10px 8px", cursor: "pointer", textAlign: "left",
                      outline: "none", transition: "opacity 0.15s, border 0.15s",
                      opacity: sel ? 1 : 0.75,
                    }}
                  >
                    <div style={{ fontSize: 12, fontWeight: 700, color: tab.fg, lineHeight: 1, marginBottom: 3 }}>{tab.label}</div>
                    <div style={{ fontSize: 9.5, color: tab.fg, opacity: 0.72 }}>{tab.sub}</div>
                  </button>
                );
              })}
            </div>

            {/* Run timing panel */}
            <AnimatePresence>
              {showRunOptions && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} exit={{ opacity: 0, height: 0 }}
                  transition={{ duration: 0.18, ease: "easeOut" }}
                  style={{ overflow: "hidden", marginBottom: 10 }}
                >
                  <div style={{ background: "rgba(255,255,255,0.045)", borderRadius: 10, padding: 12 }}>
                    <div style={{ fontSize: 10, fontWeight: 600, color: T3, textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: 8 }}>When</div>
                    <div style={{ display: "flex", gap: 6 }}>
                      {[{ label: "Now", mins: 0 }, { label: "In 5 min", mins: 5 }, { label: "In 15 min", mins: 15 }].map(t => (
                        <button key={t.mins} onClick={() => startRun(t.mins)} style={{
                          flex: 1, padding: "8px 0", borderRadius: 8, cursor: "pointer", fontWeight: 600, fontSize: 11,
                          background: "rgba(196,122,43,0.15)", border: "0.5px solid rgba(196,122,43,0.45)",
                          color: T1, ...SF,
                        }}>{t.label}</button>
                      ))}
                    </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* What's happening nearby */}
            <div style={{ marginBottom: 10 }}>
              <div style={{ display: "flex", alignItems: "center", marginBottom: 8 }}>
                <span style={{ fontSize: 11, fontWeight: 600, color: T1 }}>Nearby</span>
                {allRuns.length > 0 && <span style={{ marginLeft: "auto", fontSize: 10, color: T3 }}>{allRuns.length} active</span>}
              </div>

              {allRuns.length === 0 ? (
                <div style={{ background: CARD, border: `0.5px solid ${BORDER}`, borderRadius: 10, padding: "14px 14px" }}>
                  <div style={{ fontSize: 12, fontWeight: 600, color: T1, marginBottom: 3 }}>Nobody's brewing yet</div>
                  <div style={{ fontSize: 11, color: T2, lineHeight: 1.5 }}>Be the first — or invite a coworker so you have crew to go with.</div>
                </div>
              ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: 7 }}>
                  {allRuns.map(r => {
                    const isOwn = r.id === "own";
                    const iAmIn = amInRun(r);
                    return (
                      <div key={r.id} style={{
                        background: CARD,
                        border: `0.5px solid ${iAmIn ? "rgba(196,122,43,0.35)" : BORDER}`,
                        borderRadius: 10, padding: 10,
                      }}>
                        <div style={{ display: "flex", gap: 10, alignItems: "flex-start", marginBottom: 8 }}>
                          <Avatar name={isOwn ? "You" : r.organizer.name} online size={34} />
                          <div style={{ flex: 1, minWidth: 0 }}>
                            <div style={{ fontSize: 12, fontWeight: 600, color: T1, lineHeight: 1.3, marginBottom: 3 }}>{activityHeadline(r)}</div>
                            <div style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 11, color: T2 }}>
                              {r.organizer.note && (
                                <><span style={{ color: T3 }}>at</span><span>{r.organizer.note}</span><span style={{ color: T3, margin: "0 2px" }}>·</span></>
                              )}
                              <span>{timingPhrase(r)}</span>
                            </div>
                          </div>
                          {r.joiners.length > 0 && (
                            <div style={{ display: "flex" }}>
                              {r.joiners.slice(0, 3).map((j, i) => (
                                <span key={j.id} style={{ marginLeft: i > 0 ? -8 : 0, border: "1.5px solid #19100A", borderRadius: "50%" }}>
                                  <Avatar name={j.name} size={22} />
                                </span>
                              ))}
                            </div>
                          )}
                        </div>
                        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                          {iAmIn ? (
                            <>
                              <button onClick={logCoffee} style={{
                                background: "rgba(196,122,43,0.85)", border: "none", borderRadius: 6, padding: "5px 10px",
                                fontSize: 11, fontWeight: 600, color: "#1A0E06", cursor: "pointer", ...SF,
                              }}>Got my coffee</button>
                              <button onClick={() => leaveRun(r)} style={{ background: "none", border: "none", fontSize: 11, fontWeight: 500, color: "#FF453A", cursor: "pointer", ...SF }}>
                                {isOwn ? "Cancel" : "Leave"}
                              </button>
                              <span style={{ marginLeft: "auto", fontSize: 10, color: T3 }}>Auto-ends in 30 min</span>
                            </>
                          ) : (
                            <button onClick={() => joinRun(r)} style={{
                              background: "rgba(196,122,43,0.85)", border: "none", borderRadius: 6, padding: "5px 12px",
                              fontSize: 11, fontWeight: 600, color: "#1A0E06", cursor: "pointer", ...SF,
                            }}>Join</button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Utility section */}
            <div style={{ background: "rgba(255,255,255,0.03)", borderRadius: 10, marginBottom: 7, overflow: "hidden", border: `0.5px solid ${BORDER}` }}>
              {utilRow("Caffeinated Mode", isCaffeinated ? "Screen stays awake" : "Keep your screen awake", "#C8A840",
                <div
                  onClick={e => { e.stopPropagation(); setIsCaffeinated(v => !v); }}
                  style={{ width: 30, height: 17, borderRadius: 9, background: isCaffeinated ? "#C47A2B" : "rgba(255,255,255,0.14)", position: "relative", flexShrink: 0, cursor: "pointer", transition: "background 0.2s" }}
                >
                  <div style={{ position: "absolute", top: 1.5, width: 14, height: 14, borderRadius: "50%", background: "white", boxShadow: "0 1px 3px rgba(0,0,0,0.35)", left: isCaffeinated ? 14 : 2, transition: "left 0.2s" }} />
                </div>,
                () => setIsCaffeinated(v => !v)
              )}
              <div style={{ borderTop: `0.5px solid ${BORDER}` }} />
              {utilRow("Add note", savedNote || "Location, timing — anything useful", "#7A9BD9",
                <span style={{ fontSize: 11, color: T3, display: "inline-block", transition: "transform 0.18s", transform: showNoteField ? "rotate(90deg)" : "none" }}>›</span>,
                () => { if (!showNoteField) setNoteDraft(savedNote); setShowNoteField(v => !v); setShowRunOptions(false); }
              )}
              <AnimatePresence>
                {showNoteField && (
                  <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} transition={{ duration: 0.18 }} style={{ overflow: "hidden" }}>
                    <div style={{ padding: "6px 12px 10px 25px", display: "flex", gap: 6 }}>
                      <input
                        autoFocus
                        value={noteDraft}
                        onChange={e => setNoteDraft(e.target.value)}
                        onKeyDown={e => e.key === "Enter" && saveNote()}
                        placeholder="e.g. Meet at kitchen"
                        style={{ flex: 1, background: "rgba(255,255,255,0.07)", border: `0.5px solid ${BORDER}`, borderRadius: 6, padding: "5px 8px", fontSize: 11, color: T1, outline: "none", ...SF }}
                      />
                      <button onClick={saveNote} style={{ background: "#C47A2B", border: "none", borderRadius: 6, padding: "5px 10px", fontSize: 11, fontWeight: 600, color: "white", cursor: "pointer", ...SF }}>Save</button>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
              <div style={{ borderTop: `0.5px solid ${BORDER}` }} />
              {utilRow("Invite a coworker", "Share a link or QR code", "#7AAF72",
                <span style={{ fontSize: 11, color: T3 }}>›</span>, () => {}
              )}
              <div style={{ borderTop: `0.5px solid ${BORDER}` }} />
              {utilRow("My coffee energy", "See your streak and impact", "#C9826A",
                <span style={{ fontSize: 11, color: T3 }}>›</span>, () => {}
              )}
            </div>

            {/* Nav section */}
            <div style={{ background: "rgba(255,255,255,0.03)", borderRadius: 10, overflow: "hidden", border: `0.5px solid ${BORDER}` }}>
              {navRow("Profile")}
              <div style={{ borderTop: `0.5px solid ${BORDER}` }} />
              {navRow("Settings")}
              <div style={{ borderTop: `0.5px solid ${BORDER}` }} />
              {navRow("Quit Brwup", true)}
            </div>

            {/* Footer */}
            <div style={{ paddingTop: 10, textAlign: "center" }}>
              <span style={{ fontSize: 10, color: T3 }}>Only visible to your crew nearby</span>
            </div>

          </div>
        </div>

        <p style={{ textAlign: "center", fontSize: 11, color: "rgba(255,255,255,0.25)", marginTop: 12, letterSpacing: "0.06em" }}>
          Fully interactive — every button works
        </p>
      </div>

      {/* ── Step-by-step guide ── */}
      <div style={{ flex: 1, minWidth: 240, display: "flex", flexDirection: "column", gap: 28, paddingTop: 2 }}>
        {steps.map((s, i) => (
          <motion.div key={i}
            initial={{ opacity: 0, x: 14 }} whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-40px" }} transition={{ duration: 0.5, delay: i * 0.07 }}
            style={{ display: "flex", gap: 14, alignItems: "flex-start" }}
          >
            <div style={{
              width: 26, height: 26, borderRadius: "50%", flexShrink: 0,
              background: "rgba(196,122,43,0.12)", color: "#C47A2B",
              border: "1px solid rgba(196,122,43,0.25)",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 10, fontWeight: 700, marginTop: 2, letterSpacing: "-0.01em",
            }}>{i + 1}</div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600, color: "rgba(255,255,255,0.88)", marginBottom: 5 }}>{s.title}</div>
              <div style={{ fontSize: 13, color: "rgba(255,255,255,0.38)", lineHeight: 1.7 }}>{s.desc}</div>
            </div>
          </motion.div>
        ))}
      </div>

    </div>
  );
}

// ─── Landing Page ─────────────────────────────────────────────────────────────

export default function Home() {
  return (
    <div className="min-h-screen bg-[var(--cream)] text-[var(--espresso)] relative" style={{ fontFamily: "'DM Sans', sans-serif" }}>
      <style>{`
        @keyframes breathe {
          0%   { transform: scale(0.65); opacity: 0.5; }
          100% { transform: scale(1.65); opacity: 0; }
        }
      `}</style>

      {/* Nav */}
      <nav className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-4 md:px-14 md:py-5 bg-[var(--cream)]/90 backdrop-blur-md border-b border-[var(--caramel)]/10">
        <img src="/brwup-logo.png" alt="Brwup" className="h-8 w-auto object-contain" />
        <div className="hidden md:flex items-center gap-9 text-[11px] tracking-widest uppercase text-[var(--latte)]">
          <a href="#demo"         className="hover:text-[var(--espresso)] transition-colors">Demo</a>
          <a href="#how-it-works" className="hover:text-[var(--espresso)] transition-colors">How it works</a>
          <a href="#privacy"      className="hover:text-[var(--espresso)] transition-colors">Privacy</a>
          <a href="#download"     className="bg-[var(--espresso)] text-[var(--cream)] px-5 py-2.5 rounded-full hover:bg-[var(--caramel)] transition-colors">Download</a>
        </div>
      </nav>

      {/* Hero */}
      <section className="min-h-screen flex flex-col items-center justify-start pt-32 pb-0 px-6 md:px-14 relative overflow-hidden">
        <div className="text-center max-w-xl relative z-10">

          <motion.div
            initial="hidden" animate="visible" variants={fadeUp} transition={{ duration: 0.5 }}
            className="inline-flex items-center gap-2.5 bg-[var(--foam)] border border-[var(--caramel)]/20 rounded-full px-4 py-1.5 text-[10px] tracking-widest uppercase text-[var(--caramel)] mb-8"
          >
            <span className="w-1.5 h-1.5 rounded-full bg-[var(--caramel)] animate-pulse" />
            macOS Menu Bar App
          </motion.div>

          <motion.h1
            initial="hidden" animate="visible" variants={fadeUp} transition={{ duration: 0.6, delay: 0.08 }}
            className="text-[clamp(34px,4vw,58px)] leading-[1.07] tracking-tight font-semibold mb-6"
          >
            The quickest way to grab<br />coffee <span className="text-[var(--caramel)]">with your team.</span>
          </motion.h1>

          <motion.p
            initial="hidden" animate="visible" variants={fadeUp} transition={{ duration: 0.6, delay: 0.16 }}
            className="text-[16px] leading-relaxed text-[var(--latte)] max-w-[400px] mx-auto mb-8"
          >
            No notifications. No group chats. No accounts. Just a quiet signal that you're heading out — and whoever wants to join, can.
          </motion.p>

          <motion.div
            initial="hidden" animate="visible" variants={fadeUp} transition={{ duration: 0.6, delay: 0.24 }}
            className="flex items-center justify-center gap-6"
          >
            <a href="#download" className="bg-[var(--espresso)] text-[var(--cream)] px-7 py-3.5 rounded-full text-[13px] font-medium inline-flex items-center gap-2.5 shadow-[0_4px_24px_rgba(42,26,14,0.16)] hover:bg-[var(--caramel)] hover:-translate-y-0.5 transition-all">
              Download Free
              <span className="opacity-40 text-[10px]">2.3 MB</span>
            </a>
            <a href="#demo" className="text-[11px] tracking-wider text-[var(--latte)] hover:text-[var(--espresso)] transition-colors">
              See the demo &rarr;
            </a>
          </motion.div>
        </div>

        {/* Hero visual */}
        <motion.div
          initial="hidden" animate="visible" variants={fadeUp} transition={{ duration: 0.9, delay: 0.32 }}
          className="relative flex items-center justify-center mt-10 z-10 w-full" style={{ minHeight: 500 }}
        >
          {[
            { text: "Leaving in 3 min",       side: "right", top: "9%",  delay: 0,    dark: false },
            { text: "Who's coming?",           side: "left",  top: "17%", delay: 0.7,  dark: true  },
            { text: "I'm in — kitchen?",       side: "right", top: "47%", delay: 1.3,  dark: false },
            { text: "Floor 2, see you there",  side: "left",  top: "49%", delay: 2.0,  foam: true  },
            { text: "On my way",               side: "right", top: "75%", delay: 2.7,  dark: false },
            { text: "Just joined the run",     side: "left",  top: "73%", delay: 1.6,  dark: true  },
          ].map((b, i) => (
            <motion.div
              key={i}
              animate={{ y: [i % 2 === 0 ? -7 : 7, i % 2 === 0 ? 7 : -7, i % 2 === 0 ? -7 : 7] }}
              transition={{ duration: 3.6 + i * 0.4, repeat: Infinity, ease: "easeInOut", delay: b.delay }}
              className={[
                "absolute text-[11.5px] font-[450] px-4 py-2.5 whitespace-nowrap rounded-2xl shadow-sm",
                b.side === "right" ? "rounded-bl-sm" : "rounded-br-sm",
                b.dark
                  ? "bg-[var(--espresso)] text-[var(--cream)]"
                  : (b as any).foam
                    ? "bg-[var(--foam)] border border-[var(--caramel)]/18 text-[var(--espresso)]"
                    : "bg-white border border-[var(--caramel)]/15 text-[var(--espresso)]",
              ].join(" ")}
              style={{ top: b.top, ...(b.side === "right" ? { right: "4%" } : { left: "4%" }) }}
            >
              {b.text}
            </motion.div>
          ))}
          <img
            src="/cup.png" alt="Brwup — coffee with your team"
            className="drop-shadow-2xl object-contain"
            style={{ maxWidth: 520, maxHeight: 580, width: "88%" }}
          />
        </motion.div>
      </section>

      {/* Live Demo */}
      <section id="demo" style={{ background: "linear-gradient(160deg, #0D0804 0%, #19100A 45%, #231508 100%)", position: "relative", overflow: "hidden" }}>
        {/* Ambient glow */}
        <div style={{ position: "absolute", inset: 0, pointerEvents: "none",
          background: "radial-gradient(ellipse 65% 55% at 12% 50%, rgba(196,122,43,0.07) 0%, transparent 70%), radial-gradient(ellipse 45% 65% at 88% 30%, rgba(74,107,69,0.06) 0%, transparent 70%)" }} />
        {/* Grid */}
        <div style={{ position: "absolute", inset: 0, pointerEvents: "none", opacity: 0.028,
          backgroundImage: "linear-gradient(rgba(255,255,255,0.6) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.6) 1px, transparent 1px)",
          backgroundSize: "52px 52px" }} />

        <motion.div initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-80px" }} variants={inView}
          className="relative px-6 md:px-14 py-24">
          <div style={{ maxWidth: 960, margin: "0 auto" }}>
            <div style={{ fontSize: 10, letterSpacing: "0.16em", textTransform: "uppercase", color: "#C47A2B", marginBottom: 16, fontWeight: 500 }}>
              Live demo
            </div>
            <h2 style={{ fontSize: "clamp(24px,3vw,40px)", fontWeight: 600, lineHeight: 1.12, color: "rgba(255,255,255,0.9)", marginBottom: 12, maxWidth: 460 }}>
              The real app, right here.<br /><span style={{ color: "#C47A2B" }}>Every button works.</span>
            </h2>
            <p style={{ fontSize: 15, color: "rgba(255,255,255,0.32)", lineHeight: 1.7, maxWidth: 460, marginBottom: 60 }}>
              A pixel-faithful, fully interactive replica. Start a run, join Maya's, toggle Caffeinated Mode, add a note — it all works exactly like the real app.
            </p>
            <AppDemo />
          </div>
        </motion.div>
      </section>

      {/* A better kind of break */}
      <motion.section
        initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-80px" }} variants={inView}
        className="px-6 md:px-14 py-28 max-w-3xl mx-auto" id="how-it-works"
      >
        <div className="text-[10px] tracking-[0.15em] uppercase text-[var(--caramel)] mb-6 font-medium">A better kind of break</div>
        <h2 className="font-semibold leading-tight tracking-tight mb-7 max-w-lg" style={{ fontSize: "clamp(28px,3.5vw,46px)" }}>
          Real conversations happen<br /><span className="text-[var(--caramel)]">between meetings, not in them.</span>
        </h2>
        <p className="leading-[1.8] text-[var(--latte)] max-w-[540px]" style={{ fontSize: 17 }}>
          Brwup makes it effortless to step away with a colleague — the kind of moment that used to happen naturally, before everything moved into a chat window.
        </p>
      </motion.section>

      {/* Features */}
      <section className="bg-[var(--espresso)] text-[var(--cream)] mx-6 md:mx-14 rounded-[20px] overflow-hidden mb-4">
        <div className="p-10 md:p-16 lg:p-20">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-60px" }} variants={inView}>
            <div className="text-[10px] tracking-[0.15em] uppercase text-[var(--gold)] mb-5 font-medium">Designed to stay out of your way</div>
            <p className="leading-[1.8] text-[#EBDCC8]/75 max-w-[560px] mb-14" style={{ fontSize: 17 }}>
              A single indicator in your menu bar. Tap it to see who's around, start a run, or mark yourself available. When you leave, a 30-minute timer cleans up automatically.
            </p>
          </motion.div>
          <motion.div
            initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-40px" }} variants={inView}
            className="grid grid-cols-1 md:grid-cols-2 gap-x-16 gap-y-7 border-t border-white/8 pt-10"
          >
            {[
              ["One-tap status",   "Available or not, remembered across launches."],
              ["Start a run",      "For now, 5 minutes, or 15 minutes from now."],
              ["Add a note",       "Location, timing, whatever's useful — shown to your crew."],
              ["Private groups",   "Limit runs to specific teammates when you want to."],
              ["Personal stats",   "Optionally synced across your Macs via iCloud."],
              ["No servers",       "Everything stays on your local network. Nothing leaves."],
            ].map(([t, d], i) => (
              <div key={i} className="flex gap-4 items-start">
                <div className="w-px self-stretch min-h-[2.5rem] bg-[var(--gold)]/25 flex-shrink-0 mt-1" />
                <div>
                  <div className="font-semibold text-[var(--cream)] mb-1" style={{ fontSize: 15 }}>{t}</div>
                  <div className="leading-relaxed text-[#EBDCC8]/55" style={{ fontSize: 13.5 }}>{d}</div>
                </div>
              </div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Privacy */}
      <motion.section
        initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-80px" }} variants={inView}
        id="privacy" className="px-6 md:px-14 py-28 max-w-3xl mx-auto"
      >
        <div className="text-[10px] tracking-[0.15em] uppercase text-[var(--caramel)] mb-6 font-medium">Built on straightforward privacy</div>
        <h2 className="font-semibold leading-tight tracking-tight mb-7 max-w-lg" style={{ fontSize: "clamp(26px,3vw,42px)" }}>
          Not a policy.<span className="text-[var(--caramel)]"> An architecture.</span>
        </h2>
        <p className="leading-[1.8] text-[var(--latte)] max-w-[580px]" style={{ fontSize: 17 }}>
          Brwup uses Apple's Bonjour to find people on the same Wi-Fi. Traffic doesn't leave your local network. There are no servers, no analytics, no telemetry — not as a promise, but because the architecture doesn't include them.
        </p>
      </motion.section>

      {/* Download */}
      <motion.section
        initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-80px" }} variants={inView}
        id="download" className="mx-6 md:mx-14 rounded-[20px] bg-[var(--foam)] border border-[var(--caramel)]/10 p-10 md:p-16 lg:p-20 mb-4"
      >
        <div className="text-[10px] tracking-[0.15em] uppercase text-[var(--caramel)] mb-6 font-medium">Setup takes about a minute</div>
        <h2 className="font-semibold leading-tight tracking-tight mb-6 max-w-md" style={{ fontSize: "clamp(26px,3vw,44px)" }}>
          Drag it to Applications.<br /><span className="text-[var(--caramel)]">Pick a display name. Done.</span>
        </h2>
        <p className="leading-relaxed text-[var(--latte)] max-w-[440px] mb-10" style={{ fontSize: 16 }}>
          No account, no onboarding, no configuration required.
        </p>
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-5 mb-10">
          <a
            href="#"
            className="bg-[var(--espresso)] text-[var(--cream)] px-8 py-4 rounded-full font-medium shadow-md hover:bg-[var(--caramel)] hover:-translate-y-0.5 transition-all"
            style={{ fontSize: 15 }}
          >
            Download for Mac
          </a>
        </div>
        <div className="text-[var(--latte)] tracking-wide" style={{ fontSize: 11 }}>
          Free &middot; 2.3 MB &middot; Requires macOS 14 or later
        </div>
      </motion.section>

      {/* Footer */}
      <footer className="border-t border-[var(--caramel)]/10 px-6 md:px-14 py-8 flex flex-col md:flex-row items-center justify-between gap-6 tracking-wider text-[var(--latte)] mt-4" style={{ fontSize: 10.5 }}>
        <img src="/brwup-logo.png" alt="Brwup" className="h-5 w-auto object-contain opacity-70" />
        <div className="text-[var(--latte)]/60">&copy; 2026 Brwup</div>
        <div className="flex gap-7">
          <Link to="/privacy" className="hover:text-[var(--espresso)] transition-colors">Privacy Policy</Link>
          <Link to="/terms"   className="hover:text-[var(--espresso)] transition-colors">Terms</Link>
          <a href="#"         className="hover:text-[var(--espresso)] transition-colors">Twitter / X</a>
        </div>
      </footer>

    </div>
  );
}
