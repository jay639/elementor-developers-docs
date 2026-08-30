# The numerology system

Every rule below lives in `@numerology/core` as pure functions and in the database
as editable data. Nothing here is hard-coded in a screen or a route handler.

## Mulank (Driver Number)

The **day** of birth, reduced to a single digit by repeatedly adding its digits.

```
15 → 1 + 5 = 6
29 → 2 + 9 = 11 → 1 + 1 = 2
```

| Day | 1–9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 |
| --- | --- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- |
| Mulank | same | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 1 | 2 |

| Day | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 |
| --- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- | -- |
| Mulank | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 1 | 2 | 3 | 4 |

## Bhagyank (Conductor Number)

Every digit of the **complete** date of birth, reduced the same way. Day and month
are zero padded so the working matches how the date is written:

```
15/08/1995 → 1+5+0+8+1+9+9+5 = 38 → 3+8 = 11 → 1+1 = 2
```

## Number root (Lucky Number Finder)

Non-digits are discarded, then the digits are reduced:

```
MH-31-AB-1234 → 3+1+1+2+3+4 = 14 → 1+4 = 5
9876543210    → 45 → 9
```

Empty input, input with no digits and input longer than 32 digits are rejected
with a friendly message.

## Today's Lucky Number

The current date, treated exactly like a Bhagyank:

```
31/08/2026 → 3+1+0+8+2+0+2+6 = 22 → 2+2 = 4
```

It is always computed from the live date, so it changes by itself every day.

## Chaldean name numerology

| Value | Letters |
| --- | --- |
| 1 | A I J Q Y |
| 2 | B K R |
| 3 | C G L S |
| 4 | D M T |
| 5 | E H N X |
| 6 | U V W |
| 7 | O Z |
| 8 | F P |
| 9 | *(none — the Chaldean system assigns no letter to 9)* |

```
RAHUL → R2 + A1 + H5 + U6 + L3 = 17   (compound number)
                              17 → 8   (root number)
```

Both numbers are returned and stored. The compound number is meaningful in its own
right and is never discarded. The table is editable in **Admin → Chaldean mapping**;
a letter may be mapped only once, and the API rejects a table that breaks that rule.

## Number compatibility (Lucky Number Finder, name vs date of birth)

Each number 1–9 has a friendly / neutral / unfriendly list. The entered root is
compared against the user's Mulank *and* Bhagyank:

* both axes friendly → **Strong Match**
* one axis friendly → **Good Match**
* both unfriendly → **Weak Match**
* otherwise → **Neutral**

Editable in **Admin → Number compatibility**, where each number must be assigned to
exactly one category.

## Marriage compatibility — evaluated in both directions

The traditional table is written from one person's Mulank outwards:

| Mulank | Matches partner Mulank **or** Bhagyank |
| --- | --- |
| 1 | 1, 4, 7 |
| 2 | 2, 7 |
| 3 | 3 |
| 4 | 1, 4 |
| 5 | 5, 6 |
| 6 | 5, 6, 9 |
| 7 | 1, 2, 7 |
| 8 | 1, 3, 5, 6 |
| 9 | 6, 9 |

Reading that table only from the man's Mulank silently assumes his number is the
only controlling one. This engine runs the table **twice**:

```
Direction A  male Mulank   → female Mulank / female Bhagyank
Direction B  female Mulank → male Mulank   / male Bhagyank
```

and grades the outcome:

| Directions matched | Verdict |
| --- | --- |
| 2 | **Strong Match** — both partners' rules accept the other |
| 1 | **Good Match** — one direction matches; the result names which |
| 0 | **Not Matched** |

A match through the Bhagyank is reported explicitly ("Compatibility found through
the Bhagyank"), and the compatible lists for each direction are shown so the user
can see exactly why. Because both directions are evaluated, the verdict is the
same whichever partner is entered first.

The score (0–100) is weighted: a Mulank match scores higher than a Bhagyank-only
match, and both weights are stored in the `marriage.scoreWeights` setting so the
grading can be tuned from the admin panel without a code change.

### Language used for results

A "Not Matched" result never says a marriage will fail. It states that, according
to the configured rules, the numbers do not show a direct match, and offers a
deeper traditional assessment with a qualified astrologer. The app does not perform
Vedic Kundali calculations and says so.

## Extending the system

The database and the engine are structured so future modules — Lo Shu grid, lucky
colours and dates, business/vehicle/house numerology, reports, subscriptions — can
be added as new rule tables and new content types without changing the existing
calculation paths.
