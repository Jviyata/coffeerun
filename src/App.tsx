import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "./pages/home";
import Privacy from "./pages/privacy";
import Terms from "./pages/terms";
import Copyright from "./pages/copyright";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/privacy" element={<Privacy />} />
        <Route path="/terms" element={<Terms />} />
        <Route path="/copyright" element={<Copyright />} />
      </Routes>
    </BrowserRouter>
  );
}
