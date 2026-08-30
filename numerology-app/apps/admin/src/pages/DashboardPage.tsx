import { useState } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, ErrorState, Loading, Stat } from '../components/ui';

interface Overview {
  totals: { users: number; activeUsers: number; newUsers: number; calculations: number; guests: number };
  calculationsByType: Array<{ type: string; count: number }>;
  topEvents: Array<{ name: string; count: number }>;
  dailyActivity: Array<{ date: string; calculations: number; events: number }>;
  localeBreakdown: Array<{ locale: string; users: number }>;
}

const TYPE_LABELS: Record<string, string> = {
  CORE_NUMBERS: 'Mulank & Bhagyank',
  LUCKY_NUMBER: 'Lucky number',
  NAME_NUMEROLOGY: 'Name numerology',
  MARRIAGE_COMPATIBILITY: 'Compatibility',
  DAILY_NUMBER: "Today's number",
};

const LOCALE_LABELS: Record<string, string> = { en: 'English', hi: 'हिन्दी', mr: 'मराठी' };
const COLORS = ['#12203F', '#C9A227', '#5A7BB5', '#8C6FB1', '#3F8F6B'];

export function DashboardPage() {
  const [days, setDays] = useState(30);
  const { data, loading, error, reload } = useAsync(
    async () => (await api<Overview>('/admin/analytics', { query: { days } })).data,
    [days],
  );

  if (loading) return <Loading rows={6} label="Loading analytics…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;
  if (!data) return null;

  const byType = data.calculationsByType.map((row) => ({
    name: TYPE_LABELS[row.type] ?? row.type,
    count: row.count,
  }));
  const byLocale = data.localeBreakdown.map((row) => ({
    name: LOCALE_LABELS[row.locale] ?? row.locale,
    value: row.users,
  }));

  return (
    <>
      <header style={{ marginBottom: 18, display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 12 }}>
        <div>
          <h1>Dashboard</h1>
          <p className="muted">Usage across the last {days} days.</p>
        </div>
        <div style={{ minWidth: 160 }}>
          <label htmlFor="range">Date range</label>
          <select id="range" value={days} onChange={(event) => setDays(Number(event.target.value))}>
            <option value={7}>Last 7 days</option>
            <option value={30}>Last 30 days</option>
            <option value={90}>Last 90 days</option>
          </select>
        </div>
      </header>

      <div className="grid stats">
        <Stat label="Total users" value={data.totals.users} hint={`${data.totals.guests} guest sessions`} />
        <Stat label="Active (7 days)" value={data.totals.activeUsers} />
        <Stat label="New users" value={data.totals.newUsers} hint={`in the last ${days} days`} />
        <Stat label="Calculations" value={data.totals.calculations} hint="all time" />
      </div>

      <div className="grid two" style={{ marginTop: 16 }}>
        <Card title="Daily activity">
          <div style={{ height: 260 }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={data.dailyActivity} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(value: string) => value.slice(5)} />
                <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
                <Tooltip />
                <Line type="monotone" dataKey="calculations" stroke="#12203F" strokeWidth={2} dot={false} name="Calculations" />
                <Line type="monotone" dataKey="events" stroke="#C9A227" strokeWidth={2} dot={false} name="Events" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card title="Most used features">
          {byType.length === 0 ? (
            <p className="muted">No calculations recorded in this period yet.</p>
          ) : (
            <div style={{ height: 260 }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={byType} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                  <XAxis dataKey="name" tick={{ fontSize: 10.5 }} interval={0} angle={-12} textAnchor="end" height={54} />
                  <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="count" fill="#12203F" radius={[6, 6, 0, 0]} name="Calculations" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </Card>
      </div>

      <div className="grid two" style={{ marginTop: 16 }}>
        <Card title="Language preference">
          {byLocale.length === 0 ? (
            <p className="muted">No language preferences saved yet.</p>
          ) : (
            <div style={{ height: 220 }}>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={byLocale} dataKey="value" nameKey="name" outerRadius={80} label>
                    {byLocale.map((entry, index) => (
                      <Cell key={entry.name} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
          )}
        </Card>

        <Card title="Top analytics events">
          {data.topEvents.length === 0 ? (
            <p className="muted">No events recorded. Events are only stored for users who allow analytics.</p>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Event</th>
                    <th>Count</th>
                  </tr>
                </thead>
                <tbody>
                  {data.topEvents.map((event) => (
                    <tr key={event.name}>
                      <td className="mono">{event.name}</td>
                      <td>{event.count}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </div>
    </>
  );
}
