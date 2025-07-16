import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

// Temporarily bypass Okta wrapper for development
createRoot(document.getElementById("root")!).render(
  <App />
);
