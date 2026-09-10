import { createContext, useContext, useMemo, type ReactNode } from "react";
import {
  MountPoints,
  type ExternalComponentModule,
  type ExternalModule,
  type ExternalNavItem,
  type ExternalPageModule,
} from "./modules";

const ModuleContext = createContext<ExternalModule[]>([]);

export function ModuleProvider(props: {
  modules: ExternalModule[];
  children: ReactNode;
}) {
  const { modules, children } = props;
  const value = useMemo(() => modules, [modules]);
  return (
    <ModuleContext.Provider value={value}>{children}</ModuleContext.Provider>
  );
}

export function useComponentModules(
  mountPoint: MountPoints.TopRightPanel,
): ExternalComponentModule[] {
  return useContext(ModuleContext).filter(
    (m): m is ExternalComponentModule =>
      m.kind === "component" && m.mountPoint === mountPoint,
  );
}

export function usePageModules(): ExternalPageModule[] {
  return useContext(ModuleContext).filter(
    (m): m is ExternalPageModule => m.kind === "page",
  );
}

export function useNavItems(): ExternalNavItem[] {
  return useContext(ModuleContext).filter(
    (m): m is ExternalNavItem => m.kind === "nav-item",
  );
}
