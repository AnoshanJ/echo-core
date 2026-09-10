import { Link, Route, Routes, useSearchParams } from "react-router-dom";
import { CORE_BUILD, CORE_FEATURES } from "./build-info";
import {
  ModuleProvider,
  useComponentModules,
  useNavItems,
  usePageModules,
} from "./ModuleProvider";
import { MountPoints, type ExternalModule } from "./modules";

function useMessage() {
  const [params] = useSearchParams();
  return params.get("msg") ?? "";
}

function EchoPage() {
  return (
    <main>
      <p data-source="core">source:core</p>
      <p data-msg>msg:{useMessage()}</p>
      <p data-features>features:{CORE_FEATURES.join(",")}</p>
      <p data-core-build>
        core:{CORE_BUILD.version}+{CORE_BUILD.commit}
      </p>
    </main>
  );
}

function NotFound() {
  return <main data-not-found>not-found</main>;
}

function TopRightPanel() {
  return (
    <div data-slot={MountPoints.TopRightPanel}>
      {useComponentModules(MountPoints.TopRightPanel).map((m) => (
        <m.component key={m.moduleName} coreVersion={CORE_BUILD.version} />
      ))}
    </div>
  );
}

function Nav() {
  return (
    <nav>
      <Link to="/">echo</Link>
      {useNavItems().map((item) => (
        <Link key={item.moduleName} to={item.route}>
          {item.title}
        </Link>
      ))}
    </nav>
  );
}

function Shell() {
  const message = useMessage();
  return (
    <div>
      <header>
        <h1>echo-core-ui</h1>
        <TopRightPanel />
      </header>
      <Nav />
      <Routes>
        <Route path="/" element={<EchoPage />} />
        {usePageModules().map((m) => (
          <Route
            key={m.moduleName}
            path={m.path}
            element={<m.pageComponent message={message} />}
          />
        ))}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </div>
  );
}

export function EchoApp(props: { externalModules?: ExternalModule[] }) {
  return (
    <ModuleProvider modules={props.externalModules ?? []}>
      <Shell />
    </ModuleProvider>
  );
}
