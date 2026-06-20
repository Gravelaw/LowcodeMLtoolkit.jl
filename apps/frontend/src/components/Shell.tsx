import type { ComponentType } from "react";
import {
  Activity,
  BarChart3,
  Boxes,
  BrainCircuit,
  Database,
  FolderOpen,
  GitBranch,
  Grid3X3,
  HelpCircle,
  Package,
  Settings,
  Share2
} from "lucide-react";
import { Button, StatusPill } from "./ui";
import type { AppView } from "../types";
import type { LucideProps } from "lucide-react";

const navItems: Array<{ id: AppView; label: string; path: string; icon: ComponentType<LucideProps> }> = [
  { id: "explorer", label: "Explorer", path: "/", icon: FolderOpen },
  { id: "data", label: "Data", path: "/data", icon: Database },
  { id: "visualize", label: "Visualize", path: "/visualize", icon: BarChart3 },
  { id: "transform", label: "Transform", path: "/transform", icon: GitBranch },
  { id: "ml-studio", label: "ML Studio", path: "/ml-studio", icon: BrainCircuit },
  { id: "models", label: "Models", path: "/models", icon: Boxes },
  { id: "deploy", label: "Deploy", path: "/deploy", icon: Package },
  { id: "monitor", label: "Monitor", path: "/monitor", icon: Activity },
  { id: "settings", label: "Settings", path: "/settings", icon: Settings }
];

export function pathForView(view: AppView) {
  return navItems.find((item) => item.id === view)?.path ?? "/";
}

export function viewFromPath(pathname: string): AppView {
  if (pathname.startsWith("/data")) return "data";
  if (pathname.startsWith("/visualize") || pathname.startsWith("/dashboard")) return "visualize";
  if (pathname.startsWith("/transform")) return "transform";
  if (pathname.startsWith("/ml-studio")) return "ml-studio";
  if (pathname.startsWith("/models")) return "models";
  if (pathname.startsWith("/deploy")) return "deploy";
  if (pathname.startsWith("/monitor")) return "monitor";
  if (pathname.startsWith("/settings")) return "settings";
  return "explorer";
}

export function Shell({
  activeView,
  children,
  onNavigate,
  onPrimaryAction,
  onGridAction,
  onShareAction,
  onHelpAction,
  onProfileAction
}: {
  activeView: AppView;
  children: React.ReactNode;
  onNavigate: (view: AppView) => void;
  onPrimaryAction: () => void;
  onGridAction: () => void;
  onShareAction: () => void;
  onHelpAction: () => void;
  onProfileAction: () => void;
}) {
  return (
    <div className="local-shell">
      <aside className="sidebar" aria-label="JuliaFlow Local navigation">
        <div className="brand">
          <div className="brand-mark" aria-hidden="true">
            <span />
            <span />
            <span />
            <span />
          </div>
          <strong>JuliaFlow Local</strong>
        </div>
        <p className="brand-copy">Low code EDA and ML built for Julia. Runs 100% locally.</p>
        <nav>
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                aria-current={activeView === item.id ? "page" : undefined}
                className={activeView === item.id ? "active" : ""}
                type="button"
                onClick={() => onNavigate(item.id)}
              >
                <span aria-hidden="true" className="nav-icon"><Icon size={17} strokeWidth={1.9} /></span>
                {item.label}
              </button>
            );
          })}
        </nav>
        <div className="local-proof">
          <strong>julia</strong>
          <p>100% local. Your data stays on your device. Always.</p>
        </div>
        <div className="sidebar-foot">
          <StatusPill tone="green">Julia 1.10.2 Local</StatusPill>
          <StatusPill tone="purple">Offline Mode</StatusPill>
        </div>
      </aside>
      <main className="workspace">
        <header className="top-strip">
          <div className="local-status" role="status" aria-label="100% Local status">
            <strong>100% Local</strong>
            <span>Offline Mode</span>
            <span>No internet required</span>
            <span>All data stays on this device</span>
          </div>
          <div className="top-actions">
            <Button variant="primary" onClick={onPrimaryAction}>+ New Project</Button>
            <Button ariaLabel="Open grid menu" onClick={onGridAction}><Grid3X3 size={17} aria-hidden="true" /></Button>
            <Button ariaLabel="Open share panel" onClick={onShareAction}><Share2 size={17} aria-hidden="true" /></Button>
            <Button ariaLabel="Open help" onClick={onHelpAction}><HelpCircle size={17} aria-hidden="true" /></Button>
            <button type="button" className="avatar" aria-label="Open local profile" onClick={onProfileAction}>AJ</button>
          </div>
        </header>
        {children}
      </main>
    </div>
  );
}
