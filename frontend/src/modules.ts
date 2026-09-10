import type { ComponentType, ReactNode } from "react";

export enum MountPoints {
  TopRightPanel = "top-right-panel",
  OrgLevelPage = "org-level-page",
  LeftNavItem = "left-nav-item",
}

interface ModuleCore {
  mountPoint: MountPoints;
  moduleName: string;
}

export interface PanelProps {
  coreVersion: string;
}

export interface PageProps {
  message: string;
}

export interface ExternalComponentModule extends ModuleCore {
  kind: "component";
  mountPoint: MountPoints.TopRightPanel;
  component: ComponentType<PanelProps>;
}

export interface ExternalPageModule extends ModuleCore {
  kind: "page";
  mountPoint: MountPoints.OrgLevelPage;
  path: string;
  pageComponent: ComponentType<PageProps>;
}

export interface ExternalNavItem extends ModuleCore {
  kind: "nav-item";
  mountPoint: MountPoints.LeftNavItem;
  title: string;
  route: string;
  icon?: ReactNode;
}

export type ExternalModule =
  | ExternalComponentModule
  | ExternalPageModule
  | ExternalNavItem;
