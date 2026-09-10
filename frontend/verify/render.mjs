import { renderToStaticMarkup } from "react-dom/server";
import { createElement } from "react";
import { MemoryRouter } from "react-router-dom";
import { EchoApp } from "../dist/index.js";

const route = process.argv[2] ?? "/";
process.stdout.write(
  renderToStaticMarkup(
    createElement(
      MemoryRouter,
      { initialEntries: [route] },
      createElement(EchoApp),
    ),
  ),
);
