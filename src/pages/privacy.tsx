import { Link } from "react-router-dom";

const SF: React.CSSProperties = { fontFamily: "'DM Sans', sans-serif" };

const Section = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <section style={{ marginBottom: 52, paddingBottom: 52, borderBottom: "1px solid rgba(196,122,43,0.1)" }}>
    <h2 style={{ fontSize: 17, fontWeight: 600, color: "#2A1A0E", marginBottom: 14, letterSpacing: "-0.01em" }}>{title}</h2>
    <div style={{ fontSize: 15, lineHeight: 1.85, color: "#7A5A40" }}>{children}</div>
  </section>
);

const P = ({ children, style }: { children: React.ReactNode; style?: React.CSSProperties }) => (
  <p style={{ marginBottom: 12, ...style }}>{children}</p>
);

const Ul = ({ items }: { items: string[] }) => (
  <ul style={{ paddingLeft: 22, margin: "10px 0 12px" }}>
    {items.map((item, i) => <li key={i} style={{ marginBottom: 7 }}>{item}</li>)}
  </ul>
);

export default function Privacy() {
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
            Privacy Policy
          </h1>
          <p style={{ fontSize: 14, color: "#B8926A", lineHeight: 1.7, marginBottom: 8 }}>
            <strong style={{ color: "#8A6A50" }}>Effective date:</strong> June 1, 2026 &nbsp;&middot;&nbsp; <strong style={{ color: "#8A6A50" }}>Last updated:</strong> June 1, 2026
          </p>
          <p style={{ fontSize: 15, color: "#8A6A50", lineHeight: 1.75 }}>
            This Privacy Policy describes how Brwup handles information when you download, install, or use the Brwup macOS application. Please read this policy carefully. By using the app, you acknowledge that you have read and understood it.
          </p>
        </div>

        <Section title="1. Who we are">
          <P>Brwup is an independent macOS application. For questions about this policy, contact us at <a href="mailto:privacy@brwup.app" style={{ color: "#C47A2B", textDecoration: "none" }}>privacy@brwup.app</a>. For the purposes of the General Data Protection Regulation (GDPR) and similar privacy laws, Brwup acts as the data controller for any personal data processed in connection with the App.</P>
        </Section>

        <Section title="2. Information we collect">
          <P><strong style={{ color: "#5A3A22" }}>2.1 Information you provide directly</strong></P>
          <P>The only personal information Brwup uses is the display name you enter when setting up the App. This name is stored locally on your Mac and broadcast over your local network to identify you to colleagues using Brwup on the same Wi-Fi network. You may also enter an optional short status note (e.g., a meeting location), which is treated identically.</P>

          <P><strong style={{ color: "#5A3A22" }}>2.2 Information collected automatically</strong></P>
          <P>Brwup does not collect any information automatically. There are no analytics libraries, crash reporters, advertising SDKs, or telemetry frameworks embedded in the App. No usage data, diagnostic data, device identifiers, IP addresses, or location data are collected or transmitted to any server operated by us or any third party.</P>

          <P><strong style={{ color: "#5A3A22" }}>2.3 Local network data</strong></P>
          <P>When the App is running, your display name and current availability status are broadcast over your local network using Apple's Bonjour (mDNS/DNS-SD) protocol. This broadcast is visible only to other devices on the same Wi-Fi network that are also running Brwup. This data does not leave your local network and is never transmitted to our servers or any external service.</P>

          <P><strong style={{ color: "#5A3A22" }}>2.4 iCloud sync (optional)</strong></P>
          <P>If you choose to enable iCloud sync in Settings, your personal usage statistics (e.g., coffee run counts and streaks) are stored in your private iCloud container using Apple's CloudKit framework. We have no access to this data — it is stored under your Apple ID and subject to <a href="https://www.apple.com/legal/privacy/" target="_blank" rel="noopener noreferrer" style={{ color: "#C47A2B", textDecoration: "none" }}>Apple's Privacy Policy</a>. iCloud sync is entirely optional and disabled by default.</P>
        </Section>

        <Section title="3. How we use information">
          <P>Because we collect no personal data on our servers, we have no data to use, sell, share, or process for business purposes. Your display name and status note are used solely to facilitate the local peer-to-peer functionality of the App — showing your availability to colleagues in the same physical space.</P>
          <P>We do not use your information for targeted advertising, profiling, sale to third parties, or any purpose other than operating the App's core functionality as described above.</P>
        </Section>

        <Section title="4. Legal basis for processing (GDPR)">
          <P>For users in the European Economic Area (EEA), United Kingdom, or Switzerland, our legal basis for processing your display name and status is <strong style={{ color: "#5A3A22" }}>legitimate interests</strong> (Article 6(1)(f) GDPR) — specifically, enabling the peer-to-peer coordination feature you have installed the App to use. Given the strictly local and minimal nature of this processing, we believe this basis is appropriate and does not override your fundamental rights.</P>
          <P>Where you voluntarily enable iCloud sync, processing of your usage statistics is based on your <strong style={{ color: "#5A3A22" }}>consent</strong> (Article 6(1)(a) GDPR), which you may withdraw at any time by disabling iCloud sync in Settings.</P>
        </Section>

        <Section title="5. Data sharing and disclosure">
          <P>We do not sell, rent, trade, or otherwise disclose your personal information to third parties, except in the following limited circumstances:</P>
          <Ul items={[
            "Apple Inc. — as described above, if you enable iCloud sync, data is stored via Apple's CloudKit. Apple's handling of this data is governed by Apple's own privacy policy.",
            "Legal obligations — we may disclose information if required by law, regulation, court order, or governmental authority. Given that we hold no personal data on our servers, any such disclosure would be limited to information we actually possess (e.g., your email if you contact us).",
            "Business transfers — in the event of a merger, acquisition, or sale of substantially all of our assets, your information (limited to any contact details you have provided us directly) may be transferred. We will notify you of any such change.",
          ]} />
        </Section>

        <Section title="6. Data retention">
          <P>Your display name and status note are stored locally on your Mac and persist until you modify or delete them within the App, or until you uninstall the App. We do not retain any personal data on external servers.</P>
          <P>If you contact us by email, we retain your correspondence for as long as reasonably necessary to respond to your inquiry and for up to 12 months thereafter, unless a longer retention period is required by law.</P>
        </Section>

        <Section title="7. Your rights">
          <P>Depending on your jurisdiction, you may have the following rights regarding your personal data:</P>
          <Ul items={[
            "Right of access — the right to request confirmation of whether we process your personal data and, if so, a copy of that data.",
            "Right to rectification — the right to correct inaccurate personal data. Within the App, you can update your display name at any time in Settings.",
            "Right to erasure — the right to request deletion of your personal data. Because we hold no data on our servers, you can effectively delete all App-related data by uninstalling Brwup. Any iCloud data can be deleted from System Settings → Apple ID → iCloud → Manage Storage.",
            "Right to restriction — the right to request that we restrict processing of your data in certain circumstances.",
            "Right to data portability — the right to receive personal data you have provided to us in a structured, machine-readable format.",
            "Right to object — the right to object to processing based on legitimate interests.",
            "Right to withdraw consent — where processing is based on consent (e.g., iCloud sync), the right to withdraw consent at any time without affecting the lawfulness of processing before withdrawal.",
            "Right to lodge a complaint — the right to lodge a complaint with a supervisory authority in your country of residence.",
          ]} />
          <P>To exercise any of these rights, contact us at <a href="mailto:privacy@brwup.app" style={{ color: "#C47A2B", textDecoration: "none" }}>privacy@brwup.app</a>. We will respond within 30 days. We may request verification of your identity before processing certain requests.</P>
        </Section>

        <Section title="8. International data transfers">
          <P>Brwup does not transfer personal data internationally, because we do not transmit or store personal data on any servers. If you enable iCloud sync, data transfers are governed by Apple's data transfer mechanisms and their compliance with applicable law.</P>
          <P>Any email correspondence you send us may be processed by our email provider, whose servers may be located in countries other than your own. We use providers that offer appropriate safeguards for such transfers.</P>
        </Section>

        <Section title="9. Security">
          <P>We take reasonable technical and organizational measures to protect any personal data we do handle (primarily email correspondence). Because the App itself stores data only locally on your device, the security of your display name and status note depends on the security of your Mac, which is managed by you and Apple.</P>
          <P>No method of transmission or storage is 100% secure. If you believe your data has been compromised, please contact us promptly at <a href="mailto:privacy@brwup.app" style={{ color: "#C47A2B", textDecoration: "none" }}>privacy@brwup.app</a>.</P>
        </Section>

        <Section title="10. Children's privacy">
          <P>Brwup is designed for workplace use and is not directed at or intended for children under the age of 13 (or 16 in certain jurisdictions). We do not knowingly collect personal data from children. If we learn that we have inadvertently collected data from a child, we will delete it promptly. If you believe a child has provided us with personal data, please contact us.</P>
        </Section>

        <Section title="11. Third-party links">
          <P>The App or its support pages may contain links to third-party websites or services (e.g., Apple's iCloud documentation). This Privacy Policy applies only to Brwup. We are not responsible for the privacy practices of third-party sites and encourage you to review their privacy policies.</P>
        </Section>

        <Section title="12. California privacy rights (CCPA / CPRA)">
          <P>If you are a California resident, you have additional rights under the California Consumer Privacy Act (CCPA) as amended by the California Privacy Rights Act (CPRA), including the right to know, the right to delete, the right to opt out of sale of personal information, and the right to non-discrimination for exercising your rights.</P>
          <P>Brwup does not sell personal information. We do not share personal information for cross-context behavioral advertising. To exercise your California rights, contact us at <a href="mailto:privacy@brwup.app" style={{ color: "#C47A2B", textDecoration: "none" }}>privacy@brwup.app</a>.</P>
        </Section>

        <Section title="13. Changes to this policy">
          <P>We may update this Privacy Policy from time to time. When we do, we will revise the "Last updated" date at the top of this page. If changes are material, we will make reasonable efforts to notify users (e.g., via an in-app notice on next launch). Your continued use of the App after the effective date of a revised policy constitutes your acceptance of the changes.</P>
          <P>We encourage you to review this policy periodically.</P>
        </Section>

        <section style={{ marginBottom: 0 }}>
          <h2 style={{ fontSize: 17, fontWeight: 600, color: "#2A1A0E", marginBottom: 14, letterSpacing: "-0.01em" }}>14. Contact us</h2>
          <div style={{ fontSize: 15, lineHeight: 1.85, color: "#7A5A40" }}>
            <P>If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:</P>
            <P>
              <strong style={{ color: "#5A3A22" }}>Email:</strong> <a href="mailto:privacy@brwup.app" style={{ color: "#C47A2B", textDecoration: "none" }}>privacy@brwup.app</a><br />
              <strong style={{ color: "#5A3A22" }}>Subject line:</strong> Privacy Inquiry
            </P>
            <P>We aim to respond to all legitimate requests within 30 days.</P>
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
          <Link to="/privacy" style={{ color: "#B8926A", textDecoration: "none" }}>Privacy Policy</Link>
          <Link to="/terms"   style={{ color: "#B8926A", textDecoration: "none" }}>Terms</Link>
        </div>
      </footer>

    </div>
  );
}
