import { useCallback, useEffect, useState } from 'react';
import { NavLink, Navigate, Route, Routes, useNavigate } from 'react-router-dom';
import { hasSession, loadProfile, logout, type AdminProfile } from './lib/api';
import { Loading } from './components/ui';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { NumbersPage } from './pages/NumbersPage';
import { CombinationsPage } from './pages/CombinationsPage';
import { CompatibilityRulesPage } from './pages/CompatibilityRulesPage';
import { NumberRulesPage } from './pages/NumberRulesPage';
import { ChaldeanPage } from './pages/ChaldeanPage';
import { UsersPage } from './pages/UsersPage';
import { SettingsPage } from './pages/SettingsPage';
import { AuditLogPage } from './pages/AuditLogPage';
import { DailyInsightsPage } from './pages/DailyInsightsPage';
import { LegalPage } from './pages/LegalPage';

interface NavItem {
  to: string;
  label: string;
  permission?: string;
  section: string;
}

const NAV: NavItem[] = [
  { to: '/', label: 'Dashboard', permission: 'analytics:read', section: 'Overview' },
  { to: '/numbers', label: 'Number content', permission: 'content:read', section: 'Numerology content' },
  { to: '/combinations', label: 'Combinations (81)', permission: 'content:read', section: 'Numerology content' },
  { to: '/daily-insights', label: "Today's number", permission: 'content:read', section: 'Numerology content' },
  { to: '/compatibility-rules', label: 'Marriage rules', permission: 'rules:read', section: 'Rules' },
  { to: '/number-rules', label: 'Number compatibility', permission: 'rules:read', section: 'Rules' },
  { to: '/chaldean', label: 'Chaldean mapping', permission: 'rules:read', section: 'Rules' },
  { to: '/users', label: 'Users', permission: 'users:read', section: 'People' },
  { to: '/settings', label: 'App settings', permission: 'settings:read', section: 'System' },
  { to: '/legal', label: 'Legal documents', permission: 'content:read', section: 'System' },
  { to: '/audit-logs', label: 'Audit log', permission: 'audit:read', section: 'System' },
];

export function App() {
  const [admin, setAdmin] = useState<AdminProfile | null>(null);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    if (!hasSession()) {
      setChecking(false);
      return;
    }
    loadProfile()
      .then(setAdmin)
      .catch(() => setAdmin(null))
      .finally(() => setChecking(false));
  }, []);

  if (checking) {
    return (
      <div className="login-shell">
        <div className="login-card">
          <Loading label="Checking your session…" rows={2} />
        </div>
      </div>
    );
  }

  if (!admin) {
    return <LoginPage onSignedIn={setAdmin} />;
  }

  return <AdminShell admin={admin} onSignedOut={() => setAdmin(null)} />;
}

function AdminShell({ admin, onSignedOut }: { admin: AdminProfile; onSignedOut: () => void }) {
  const navigate = useNavigate();
  const can = useCallback(
    (permission?: string) => !permission || admin.permissions.includes(permission),
    [admin.permissions],
  );

  const visible = NAV.filter((item) => can(item.permission));
  const sections = [...new Set(visible.map((item) => item.section))];

  const handleSignOut = async () => {
    await logout();
    onSignedOut();
    navigate('/');
  };

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark" aria-hidden="true">
            अ
          </div>
          <div>
            <div className="brand-name">Ank Jyoti</div>
            <div className="brand-env">Admin panel</div>
          </div>
        </div>

        {sections.map((section) => (
          <nav key={section} aria-label={section}>
            <div className="section-label">{section}</div>
            {visible
              .filter((item) => item.section === section)
              .map((item) => (
                <NavLink key={item.to} to={item.to} end={item.to === '/'}>
                  {item.label}
                </NavLink>
              ))}
          </nav>
        ))}

        <div className="spacer" />
        <div className="who">
          <div>{admin.name}</div>
          <div>{admin.roleName}</div>
          <button type="button" className="btn-secondary" style={{ marginTop: 10 }} onClick={handleSignOut}>
            Sign out
          </button>
        </div>
      </aside>

      <div className="main">
        {admin.mustChangePassword && (
          <div className="alert warning" style={{ margin: 16, marginBottom: 0 }}>
            This account is still using its seeded password. Change it in App settings before going live.
          </div>
        )}
        <div className="content">
          <Routes>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/numbers" element={<NumbersPage canWrite={can('content:write')} />} />
            <Route path="/combinations" element={<CombinationsPage canWrite={can('content:write')} />} />
            <Route path="/daily-insights" element={<DailyInsightsPage canWrite={can('content:write')} />} />
            <Route
              path="/compatibility-rules"
              element={<CompatibilityRulesPage canWrite={can('rules:write')} />}
            />
            <Route path="/number-rules" element={<NumberRulesPage canWrite={can('rules:write')} />} />
            <Route path="/chaldean" element={<ChaldeanPage canWrite={can('rules:write')} />} />
            <Route
              path="/users"
              element={<UsersPage canWrite={can('users:write')} canDelete={can('users:delete')} />}
            />
            <Route path="/settings" element={<SettingsPage canWrite={can('settings:write')} />} />
            <Route path="/legal" element={<LegalPage canWrite={can('content:write')} />} />
            <Route path="/audit-logs" element={<AuditLogPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </div>
      </div>
    </div>
  );
}
