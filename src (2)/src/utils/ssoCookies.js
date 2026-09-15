// Cross-subdomain session cookies, shared with the store at store.happywedz.com.
//
// HappyWedz keeps its session in localStorage. That is origin-scoped by
// definition, so the store can never read it, and the reverse is equally true.
// The store keeps its session in a `userInfo` cookie. Cookies scoped to the
// parent domain are the only channel the two apps share, so each session is
// mirrored into one:
//
//   hwUserInfo  the HappyWedz session, so the store can adopt it
//   userInfo    the store session, under the exact name the store already reads
//               (see auth-client.js) — nothing on that side needs to change to
//               pick it up
//
// A cookie's identity does not include the port, so localhost:5173 and
// localhost:3000 share these as well. SSO can be exercised entirely on a
// developer machine against the live backend, with no hosts-file entry.
//
// SECURITY: these are readable by JavaScript, because both apps need to read
// them. That is deliberate but not free — it means script injected on either
// subdomain can lift both sessions, so an XSS on the store is now also an XSS
// on HappyWedz. HttpOnly cookies set by the backend would remove that, and are
// the right end state; they cannot be read by the store's client-side session
// code as written today.

const HW_COOKIE = "hwUserInfo";
const STORE_COOKIE = "userInfo";

// On a happywedz.com host the cookie is written to the parent domain so every
// subdomain sees it. On localhost it must be omitted entirely: browsers reject
// a Domain attribute that is not a suffix of the current host, and the cookie
// is dropped without an error.
const domainClause = () =>
  window.location.hostname.endsWith("happywedz.com")
    ? "; domain=.happywedz.com"
    : "";

const secureClause = () =>
  window.location.protocol === "https:" ? "; secure" : "";

const write = (name, value, days = 7) => {
  const expires = new Date(Date.now() + days * 864e5).toUTCString();

  document.cookie =
    `${name}=${encodeURIComponent(JSON.stringify(value))}` +
    `; expires=${expires}; path=/${domainClause()}; samesite=lax${secureClause()}`;
};

// Deleting a cookie requires the same domain and path it was written with, or
// the browser quietly keeps it. Both variants are cleared because a session may
// predate this file, when cookies were host-only.
const erase = (name) => {
  const past = "Thu, 01 Jan 1970 00:00:00 GMT";
  document.cookie = `${name}=; expires=${past}; path=/${domainClause()}`;
  document.cookie = `${name}=; expires=${past}; path=/`;
};

export const readCookie = (name) => {
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  if (!match) return null;

  try {
    return JSON.parse(decodeURIComponent(match[1]));
  } catch {
    // A cookie written by something else, or truncated. Treat it as absent
    // rather than letting a parse error break app startup.
    return null;
  }
};

/**
 * Mirror a fresh HappyWedz login into both cookies.
 *
 * `storeSession` is what the backend attaches to login, register and
 * google-auth responses — an ordinary store JWT, indistinguishable from one the
 * store's own login form would have issued. It is absent when the store was
 * unreachable, which is not an error: the HappyWedz session still stands and
 * the user signs into the store separately.
 */
export const writeSsoCookies = (user, token, storeSession) => {
  write(HW_COOKIE, {
    id: user?.id,
    name: user?.name,
    email: user?.email,
    role: user?.role,
    token,
  });

  if (storeSession?.token) {
    // The store's own code reads `_id`; `withId` in its auth-client also
    // expects `id`. Write both so neither has to be special-cased.
    write(STORE_COOKIE, { ...storeSession, id: storeSession._id });
  }
};

export const clearSsoCookies = () => {
  erase(HW_COOKIE);
  erase(STORE_COOKIE);
};

export const readHwCookie = () => readCookie(HW_COOKIE);
