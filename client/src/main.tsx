import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

// Check if simple auth is enabled
const isSimpleAuth = import.meta.env.VITE_SIMPLE_AUTH === "true";

createRoot(document.getElementById("root")!).render(<App />);
