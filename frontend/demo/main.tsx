import { EchoApp } from "@anoshanj/echo-core-ui";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <BrowserRouter>
      <EchoApp />
    </BrowserRouter>
  </StrictMode>,
);
