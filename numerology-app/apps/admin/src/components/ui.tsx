import type { ReactNode } from 'react';

/** Shared presentational components, so no screen re-implements them. */

export function Card({ title, action, children }: { title?: string; action?: ReactNode; children: ReactNode }) {
  return (
    <section className="card">
      {(title ?? action) && (
        <header className="card-header">
          {title ? <h2>{title}</h2> : <span />}
          {action}
        </header>
      )}
      {children}
    </section>
  );
}

export function Stat({ label, value, hint }: { label: string; value: ReactNode; hint?: string }) {
  return (
    <div className="card stat">
      <div className="label">{label}</div>
      <div className="value">{value}</div>
      {hint && <div className="hint">{hint}</div>}
    </div>
  );
}

export function Loading({ rows = 4, label = 'Loading…' }: { rows?: number; label?: string }) {
  return (
    <div aria-busy="true" aria-live="polite">
      <span className="muted">{label}</span>
      <div style={{ marginTop: 10, display: 'grid', gap: 8 }}>
        {Array.from({ length: rows }, (_, index) => (
          <div key={index} className="skeleton" style={{ width: `${100 - index * 8}%` }} />
        ))}
      </div>
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="alert error" role="alert">
      <strong>{message}</strong>
      {onRetry && (
        <div style={{ marginTop: 10 }}>
          <button type="button" className="btn-secondary" onClick={onRetry}>
            Try again
          </button>
        </div>
      )}
    </div>
  );
}

export function EmptyState({ title, description, action }: { title: string; description?: string; action?: ReactNode }) {
  return (
    <div className="empty">
      <h3>{title}</h3>
      {description && <p>{description}</p>}
      {action}
    </div>
  );
}

export function Toast({ message, tone = 'info' }: { message: string; tone?: 'info' | 'error' }) {
  return (
    <div className={`toast ${tone === 'error' ? 'error' : ''}`} role="status" aria-live="polite">
      {message}
    </div>
  );
}

export function LocaleTabs({ value, onChange }: { value: string; onChange: (locale: string) => void }) {
  const locales = [
    { key: 'en', label: 'English' },
    { key: 'hi', label: 'हिन्दी' },
    { key: 'mr', label: 'मराठी' },
  ];
  return (
    <div className="btn-row" role="tablist" aria-label="Content language">
      {locales.map((locale) => (
        <button
          key={locale.key}
          type="button"
          role="tab"
          aria-selected={value === locale.key}
          className={value === locale.key ? 'btn-primary' : 'btn-secondary'}
          onClick={() => onChange(locale.key)}
        >
          {locale.label}
        </button>
      ))}
    </div>
  );
}

/**
 * The 1-9 selector used by every rule editor. Non-technical administrators pick
 * numbers by tapping them instead of typing a comma separated list.
 */
export function NumberPicker({
  selected,
  onToggle,
  tone = 'default',
  disabled = false,
}: {
  selected: number[];
  onToggle: (value: number) => void;
  tone?: 'default' | 'friendly' | 'unfriendly';
  disabled?: boolean;
}) {
  return (
    <div className="btn-row" style={{ gap: 6 }}>
      {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((number) => {
        const on = selected.includes(number);
        const toneClass = on ? (tone === 'default' ? 'on' : tone) : '';
        return (
          <button
            key={number}
            type="button"
            disabled={disabled}
            aria-pressed={on}
            aria-label={`Number ${number}${on ? ', selected' : ''}`}
            className={`number-chip ${toneClass}`}
            onClick={() => onToggle(number)}
          >
            {number}
          </button>
        );
      })}
    </div>
  );
}

export function Pagination({
  page,
  totalPages,
  total,
  onChange,
}: {
  page: number;
  totalPages: number;
  total: number;
  onChange: (page: number) => void;
}) {
  return (
    <div className="pagination">
      <span className="muted">
        {total} record{total === 1 ? '' : 's'} · page {page} of {totalPages}
      </span>
      <button type="button" className="btn-secondary" disabled={page <= 1} onClick={() => onChange(page - 1)}>
        Previous
      </button>
      <button
        type="button"
        className="btn-secondary"
        disabled={page >= totalPages}
        onClick={() => onChange(page + 1)}
      >
        Next
      </button>
    </div>
  );
}

/** Comma separated list editor for short string arrays (strengths, colours…). */
export function ListField({
  label,
  value,
  onChange,
  hint,
}: {
  label: string;
  value: string[];
  onChange: (value: string[]) => void;
  hint?: string;
}) {
  return (
    <div className="field">
      <label>{label}</label>
      <input
        value={value.join(', ')}
        onChange={(event) =>
          onChange(
            event.target.value
              .split(',')
              .map((item) => item.trim())
              .filter(Boolean),
          )
        }
      />
      {hint && <div className="hint">{hint}</div>}
    </div>
  );
}
