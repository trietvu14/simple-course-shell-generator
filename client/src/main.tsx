import { createRoot } from "react-dom/client";
import { Security } from '@okta/okta-react';
import { oktaAuth } from './lib/okta-config';
import App from "./App";
import "./index.css";

createRoot(document.getElementById("root")!).render(
  <Security 
    oktaAuth={oktaAuth}
    restoreOriginalUri={async (oktaAuth, originalUri) => {
      window.location.replace(originalUri || '/dashboard');
    }}
  >
    <App />
  </Security>
);
