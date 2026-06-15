import { Link } from "react-router-dom";

const SF: React.CSSProperties = { fontFamily: "'DM Sans', sans-serif" };

const Section = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <section style={{ marginBottom: 52, paddingBottom: 52, borderBottom: "1px solid rgba(196,122,43,0.1)" }}>
    <h2 style={{ fontSize: 17, fontWeight: 600, color: "#2A1A0E", marginBottom: 14, letterSpacing: "-0.01em" }}>{title}</h2>
    <div style={{ fontSize: 15, lineHeight: 1.85, color: "#7A5A40" }}>{children}</div>
  </section>
);

const P = ({ children }: { children: React.ReactNode }) => (
  <p style={{ marginBottom: 12 }}>{children}</p>
);

export default function Copyright() {
  return (
    <div style={{ ...SF, background: "#FEFCF9", minHeight: "100vh", color: "#2A1A0E" }}>

      {/* Nav */}
      <nav style={{
        position: "sticky", top: 0, zIndex: 50,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "16px 56px",
        background: "rgba(254,252,249,0.92)", backdropFilter: "blur(12px)",
        borderBottom: "1px solid rgba(196,122,43,0.1)",
      }}>
        <Link to="/">
          <img src="/brwup-logo.png" alt="Brwup" style={{ height: 30, width: "auto", objectFit: "contain" }} />
        </Link>
        <Link to="/" style={{ fontSize: 12, fontWeight: 500, color: "#B8926A", textDecoration: "none", letterSpacing: "0.06em", textTransform: "uppercase" }}>
          ← Back
        </Link>
      </nav>

      {/* Content */}
      <div style={{ maxWidth: 700, margin: "0 auto", padding: "72px 24px 96px" }}>

        {/* Header */}
        <div style={{ marginBottom: 64, paddingBottom: 48, borderBottom: "1px solid rgba(196,122,43,0.12)" }}>
          <div style={{ fontSize: 10, letterSpacing: "0.15em", textTransform: "uppercase", color: "#C47A2B", marginBottom: 16, fontWeight: 500 }}>Legal</div>
          <h1 style={{ fontSize: "clamp(32px, 4vw, 46px)", fontWeight: 600, lineHeight: 1.1, letterSpacing: "-0.02em", marginBottom: 16 }}>
            Copyright Notice
          </h1>
          <p style={{ fontSize: 15, color: "#8A6A50", lineHeight: 1.75 }}>
            This page describes the intellectual property rights that apply to Brwup and its associated materials.
          </p>
        </div>

        <Section title="Ownership">
          <P>Copyright &copy; 2026 Brwup. All rights reserved.</P>
          <P>The Brwup macOS application, including its source code, design, graphics, user interface, branding, and all associated documentation, is the exclusive intellectual property of Brwup. All rights not expressly granted are reserved.</P>
        </Section>

        <Section title="Trademark">
          <P>The name "Brwup," the Brwup logo, and any related marks, product names, and slogans are trademarks of Brwup. You may not use these marks without our prior written permission — including in domain names, app names, social media handles, or any commercial context that implies association with or endorsement by Brwup.</P>
        </Section>

        <Section title="Software license">
          <P>The Brwup application is licensed, not sold. Your right to use the app is governed by the <Link to="/terms" style={{ color: "#C47A2B", textDecoration: "none" }}>Terms and Conditions</Link>. Purchasing or downloading the app does not transfer any intellectual property rights to you.</P>
          <P>You may not copy, reproduce, redistribute, modify, decompile, reverse engineer, or create derivative works from the app or any part of it without explicit written permission from Brwup, except as required by applicable law.</P>
        </Section>

        <Section title="Open source components">
          <P>Brwup is built with open source software. The following third-party libraries are used under their respective licenses:</P>
          <div style={{ marginTop: 16, display: "flex", flexDirection: "column", gap: 12 }}>
            {[
              { name: "React", license: "MIT License", url: "https://github.com/facebook/react/blob/main/LICENSE" },
              { name: "Framer Motion", license: "MIT License", url: "https://github.com/framer/motion/blob/main/LICENSE.md" },
              { name: "React Router", license: "MIT License", url: "https://github.com/remix-run/react-router/blob/main/LICENSE.md" },
              { name: "Tailwind CSS", license: "MIT License", url: "https://github.com/tailwindlabs/tailwindcss/blob/master/LICENSE" },
              { name: "Vite", license: "MIT License", url: "https://github.com/vitejs/vite/blob/main/LICENSE" },
              { name: "DM Sans (Google Fonts)", license: "SIL Open Font License 1.1", url: "https://fonts.google.com/specimen/DM+Sans/about" },
            ].map((lib, i) => (
              <div key={i} style={{
                display: "flex", alignItems: "center", justifyContent: "space-between",
                padding: "12px 16px", background: "rgba(196,122,43,0.05)",
                borderRadius: 8, border: "1px solid rgba(196,122,43,0.1)",
                gap: 12, flexWrap: "wrap",
              }}>
                <span style={{ fontSize: 14, fontWeight: 600, color: "#2A1A0E" }}>{lib.name}</span>
                <a href={lib.url} target="_blank" rel="noopener noreferrer"
                  style={{ fontSize: 13, color: "#C47A2B", textDecoration: "none" }}>
                  {lib.license}
                </a>
              </div>
            ))}
          </div>
          <P style={{ marginTop: 16 }}>Full license texts for all open source components are available in the app bundle and their respective repositories.</P>
        </Section>

        <Section title="Website content">
          <P>All text, images, illustrations, and other content on brwup.app are copyright &copy; 2026 Brwup unless otherwise noted. You may not reproduce or republish any content from this website without written permission.</P>
          <P>The coffee cup imagery used on this website is used under license from its respective rights holder.</P>
        </Section>

        <Section title="Reporting infringement">
          <P>If you believe that any content on this website or within the Brwup app infringes your copyright, please contact us with the following information:</P>
          <ul style={{ paddingLeft: 22, margin: "10px 0 12px" }}>
            {[
              "A description of the copyrighted work you claim has been infringed",
              "A description of where the allegedly infringing material is located",
              "Your contact information (name, address, email)",
              "A statement that you have a good-faith belief that the use is not authorized",
              "A statement, under penalty of perjury, that the information in your notice is accurate and that you are the copyright owner or authorized to act on their behalf",
            ].map((item, i) => <li key={i} style={{ marginBottom: 7 }}>{item}</li>)}
          </ul>
          <P>Send notices to <a href="mailto:legal@brwup.app" style={{ color: "#C47A2B", textDecoration: "none" }}>legal@brwup.app</a> with the subject line "Copyright Infringement Notice."</P>
        </Section>

        <section style={{ marginBottom: 0 }}>
          <h2 style={{ fontSize: 17, fontWeight: 600, color: "#2A1A0E", marginBottom: 14, letterSpacing: "-0.01em" }}>Contact</h2>
          <div style={{ fontSize: 15, lineHeight: 1.85, color: "#7A5A40" }}>
            <p style={{ marginBottom: 12 }}>For any copyright-related inquiries, please reach out to us at <a href="mailto:legal@brwup.app" style={{ color: "#C47A2B", textDecoration: "none" }}>legal@brwup.app</a>.</p>
          </div>
        </section>

      </div>

      {/* Footer */}
      <footer style={{
        borderTop: "1px solid rgba(196,122,43,0.1)", padding: "28px 56px",
        display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 16,
        fontSize: 11, color: "#B8926A", letterSpacing: "0.05em",
      }}>
        <Link to="/"><img src="/brwup-logo.png" alt="Brwup" style={{ height: 20, width: "auto", objectFit: "contain", opacity: 0.65 }} /></Link>
        <span style={{ opacity: 0.55 }}>&copy; 2026 Brwup</span>
        <div style={{ display: "flex", gap: 24 }}>
          <Link to="/privacy"   style={{ color: "#B8926A", textDecoration: "none" }}>Privacy Policy</Link>
          <Link to="/terms"     style={{ color: "#B8926A", textDecoration: "none" }}>Terms</Link>
          <Link to="/copyright" style={{ color: "#B8926A", textDecoration: "none" }}>Copyright</Link>
        </div>
      </footer>

    </div>
  );
}
