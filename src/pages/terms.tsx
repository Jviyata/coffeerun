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

export default function Terms() {
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
            Terms & Conditions
          </h1>
          <p style={{ fontSize: 14, color: "#B8926A", lineHeight: 1.7, marginBottom: 8 }}>
            <strong style={{ color: "#8A6A50" }}>Effective date:</strong> June 1, 2026 &nbsp;&middot;&nbsp; <strong style={{ color: "#8A6A50" }}>Last updated:</strong> June 1, 2026
          </p>
          <p style={{ fontSize: 15, color: "#8A6A50", lineHeight: 1.75 }}>
            These Terms and Conditions govern your access to and use of the Brwup macOS application provided by Brwup. By downloading, installing, or using the app, you agree to be bound by these terms. If you do not agree, do not download or use the app.
          </p>
        </div>

        <Section title="1. License grant">
          <P>Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable, personal license to download, install, and use the App on Apple-branded devices that you own or control, solely for your personal or internal business purposes.</P>
          <P>This license does not include the right to: (a) sublicense, sell, resell, transfer, assign, or otherwise commercially exploit the App; (b) modify, translate, adapt, or create derivative works based on the App; (c) reverse engineer, decompile, disassemble, or attempt to extract the source code of the App, except as permitted by applicable law; or (d) remove or alter any proprietary notices, labels, or marks on the App.</P>
        </Section>

        <Section title="2. Eligibility">
          <P>You must be at least 13 years of age (or 16 years of age in the European Economic Area) to use the App. By using the App, you represent and warrant that you meet this age requirement. If you are using the App on behalf of an employer or other organization, you represent that you have the authority to bind that organization to these Terms, and references to "you" include both you individually and that organization.</P>
        </Section>

        <Section title="3. Apple App Store terms">
          <P>If you download the App from the Apple App Store, your use of the App is also subject to Apple's <a href="https://www.apple.com/legal/internet-services/itunes/us/terms.html" target="_blank" rel="noopener noreferrer" style={{ color: "#C47A2B", textDecoration: "none" }}>Media Services Terms and Conditions</a>. In the event of any conflict between these Terms and Apple's terms, these Terms govern to the extent of the conflict. Apple is not a party to these Terms and bears no responsibility for the App or its content.</P>
          <P>You acknowledge that Apple has no obligation to provide maintenance or support services for the App, and that Apple is not responsible for addressing any claims relating to the App, including product liability claims, consumer protection claims, intellectual property infringement claims, or any other claims.</P>
        </Section>

        <Section title="4. Acceptable use">
          <P>You agree to use the App only for its intended purpose — coordinating informal coffee breaks and similar spontaneous gatherings with colleagues on the same local network — and in compliance with all applicable laws and regulations. You agree not to:</P>
          <Ul items={[
            "Use the App to harass, intimidate, stalk, or harm any person;",
            "Use the App to transmit any unlawful, defamatory, obscene, or otherwise objectionable content via its status or note features;",
            "Attempt to intercept, monitor, modify, or interfere with local network traffic generated by the App or by other users' instances of the App;",
            "Use the App in any manner that could disable, overburden, damage, or impair the App or networks connected to the App;",
            "Use any automated means, bot, script, or other mechanism to access or interact with the App in a manner not intended by its design;",
            "Use the App in violation of your employer's acceptable use policies or any applicable workplace regulations;",
            "Violate any applicable local, national, or international law or regulation in connection with your use of the App.",
          ]} />
        </Section>

        <Section title="5. Privacy">
          <P>Your use of the App is also governed by our <Link to="/privacy" style={{ color: "#C47A2B", textDecoration: "none" }}>Privacy Policy</Link>, which is incorporated into these Terms by reference. Please review the Privacy Policy to understand our practices. By using the App, you acknowledge that you have read and understood the Privacy Policy.</P>
        </Section>

        <Section title="6. Local network and iCloud">
          <P><strong style={{ color: "#5A3A22" }}>Local network.</strong> The App requires access to your local Wi-Fi network to function. By using the App, you consent to your display name and status being broadcast over your local network via Apple's Bonjour protocol, visible to other devices running the App on the same network. You are responsible for ensuring that your use of local network broadcasting complies with any applicable workplace, network, or legal policies.</P>
          <P><strong style={{ color: "#5A3A22" }}>iCloud.</strong> If you enable optional iCloud sync, your usage statistics are stored in your private iCloud container via Apple's CloudKit. Your use of iCloud is subject to <a href="https://www.apple.com/legal/internet-services/icloud/" target="_blank" rel="noopener noreferrer" style={{ color: "#C47A2B", textDecoration: "none" }}>Apple's iCloud Terms of Service</a>. We have no access to data stored in your iCloud container.</P>
        </Section>

        <Section title="7. Intellectual property">
          <P>The App and all content, features, and functionality thereof — including but not limited to software, text, graphics, logos, icons, and the compilation thereof — are owned by Brwup or its licensors and are protected by copyright, trademark, and other intellectual property laws.</P>
          <P>These Terms do not transfer any intellectual property rights to you. The Brwup name, logo, and related marks are trademarks of Brwup. You may not use our trademarks without our prior written consent.</P>
          <P>If you provide us with any feedback, suggestions, or ideas about the app, you grant us a perpetual, irrevocable, royalty-free, worldwide license to use, reproduce, modify, and incorporate that feedback into the app or other products without any obligation to you.</P>
        </Section>

        <Section title="8. Updates and availability">
          <P>We may release updates to the App from time to time, which may add, modify, or remove features. While we aim to maintain backward compatibility, we do not guarantee that any particular feature will be available indefinitely. We reserve the right to discontinue the App at any time with reasonable notice where practicable.</P>
          <P>The App is provided as-is and we make no guarantee of continuous availability. We are not liable for any interruption, delay, or failure in the App's operation.</P>
        </Section>

        <Section title="9. Disclaimer of warranties">
          <P style={{ textTransform: "uppercase", fontSize: 13.5, letterSpacing: "0.01em", color: "#5A3A22" }}>
            <strong>The app is provided "as is" and "as available," without warranty of any kind, express or implied. To the fullest extent permitted by applicable law, we disclaim all warranties, including but not limited to implied warranties of merchantability, fitness for a particular purpose, title, and non-infringement.</strong>
          </P>
          <P>We do not warrant that: (a) the App will meet your requirements or expectations; (b) the App will be available uninterrupted, timely, secure, or error-free; (c) any defects or errors will be corrected; or (d) the App is free of viruses or other harmful components. Some jurisdictions do not allow the exclusion of certain warranties, so some of the above exclusions may not apply to you.</P>
        </Section>

        <Section title="10. Limitation of liability">
          <P style={{ textTransform: "uppercase", fontSize: 13.5, letterSpacing: "0.01em", color: "#5A3A22" }}>
            <strong>To the fullest extent permitted by applicable law, in no event shall Brwup, its developers, officers, employees, agents, or licensors be liable for any indirect, incidental, special, consequential, punitive, or exemplary damages, including but not limited to loss of profits, data, goodwill, or other intangible losses, arising out of or in connection with your use of or inability to use the App, even if we have been advised of the possibility of such damages.</strong>
          </P>
          <P>To the extent that any liability is not excluded by law, our total cumulative liability to you for any claims arising out of or related to these Terms or the App shall not exceed the greater of (a) the amount you paid us for the App in the twelve months preceding the claim (which for a free app is zero) or (b) one hundred US dollars (USD $100).</P>
          <P>Some jurisdictions do not allow the limitation or exclusion of liability for incidental or consequential damages. In such jurisdictions, our liability is limited to the maximum extent permitted by law.</P>
        </Section>

        <Section title="11. Indemnification">
          <P>You agree to defend, indemnify, and hold harmless Brwup and its developers, officers, employees, agents, and licensors from and against any claims, damages, losses, liabilities, costs, and expenses (including reasonable legal fees) arising out of or relating to: (a) your use of the App; (b) your violation of these Terms; (c) your violation of any applicable law or the rights of any third party; or (d) your use of the App's local network broadcasting features in violation of any workplace or network policy.</P>
        </Section>

        <Section title="12. Termination">
          <P>These Terms are effective until terminated. Your rights under these Terms will terminate automatically and without notice if you fail to comply with any provision of these Terms. Upon termination, you must cease all use of the App and delete all copies in your possession.</P>
          <P>We reserve the right to suspend or terminate your access to the App at any time, for any reason, with or without notice. Sections 7, 9, 10, 11, 13, and 14 survive any termination of these Terms.</P>
        </Section>

        <Section title="13. Governing law and dispute resolution">
          <P><strong style={{ color: "#5A3A22" }}>Governing law.</strong> These Terms are governed by and construed in accordance with applicable law, without regard to its conflict of law provisions. If you are a consumer in the European Union, you also benefit from any mandatory provisions of the law of the country in which you are resident.</P>
          <P><strong style={{ color: "#5A3A22" }}>Informal resolution.</strong> Before filing any formal legal claim, you agree to contact us at <a href="mailto:legal@brwup.app" style={{ color: "#C47A2B", textDecoration: "none" }}>legal@brwup.app</a> and attempt to resolve the dispute informally. We will attempt to resolve the dispute within 30 days of receiving your notice.</P>
          <P><strong style={{ color: "#5A3A22" }}>EU users.</strong> If you are a consumer resident in the EU, you may also use the European Commission's Online Dispute Resolution platform at <a href="https://ec.europa.eu/consumers/odr" target="_blank" rel="noopener noreferrer" style={{ color: "#C47A2B", textDecoration: "none" }}>ec.europa.eu/consumers/odr</a>.</P>
          <P><strong style={{ color: "#5A3A22" }}>Class action waiver.</strong> To the extent permitted by applicable law, you waive any right to bring or participate in any class, collective, or representative proceeding against us.</P>
        </Section>

        <Section title="14. General provisions">
          <P><strong style={{ color: "#5A3A22" }}>Entire agreement.</strong> These Terms, together with the Privacy Policy, constitute the entire agreement between you and Brwup with respect to the App and supersede all prior agreements, representations, and understandings.</P>
          <P><strong style={{ color: "#5A3A22" }}>Severability.</strong> If any provision of these Terms is found to be invalid or unenforceable, that provision will be enforced to the maximum extent permissible, and the remaining provisions will continue in full force and effect.</P>
          <P><strong style={{ color: "#5A3A22" }}>Waiver.</strong> Our failure to enforce any right or provision of these Terms shall not constitute a waiver of such right or provision unless acknowledged and agreed to by us in writing.</P>
          <P><strong style={{ color: "#5A3A22" }}>Assignment.</strong> You may not assign or transfer these Terms or any rights hereunder without our prior written consent. We may assign these Terms freely, including in connection with a merger, acquisition, or sale of assets.</P>
          <P><strong style={{ color: "#5A3A22" }}>No third-party beneficiaries.</strong> These Terms do not create any third-party beneficiary rights, except that Apple and its subsidiaries are third-party beneficiaries of Section 3 and may enforce it against you.</P>
        </Section>

        <Section title="15. Changes to these terms">
          <P>We may revise these Terms from time to time. When we make material changes, we will update the "Last updated" date and, where reasonably practicable, provide notice (such as an in-app notification on next launch). Your continued use of the App after the effective date of the revised Terms constitutes your acceptance of the changes.</P>
          <P>If you do not agree to the revised Terms, your sole remedy is to stop using the App and uninstall it.</P>
        </Section>

        <section style={{ marginBottom: 0 }}>
          <h2 style={{ fontSize: 17, fontWeight: 600, color: "#2A1A0E", marginBottom: 14, letterSpacing: "-0.01em" }}>16. Contact us</h2>
          <div style={{ fontSize: 15, lineHeight: 1.85, color: "#7A5A40" }}>
            <P>If you have questions about these Terms, please contact us:</P>
            <P>
              <strong style={{ color: "#5A3A22" }}>Email:</strong> <a href="mailto:legal@brwup.app" style={{ color: "#C47A2B", textDecoration: "none" }}>legal@brwup.app</a><br />
              <strong style={{ color: "#5A3A22" }}>Subject line:</strong> Terms Inquiry
            </P>
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
