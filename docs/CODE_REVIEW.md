# Secure Code Review Exercise: Broken Access Control

This document walks through a deliberate flaw added to the sample app on a practice branch, how it is spotted in review, a custom Semgrep rule that detects it, and the fix.

**Practice branch:** `demo/vulnerable-endpoint` (never merged into `main`). The flaw runs only in tests and in CI on fake data.

## Summary

| Item | Detail |
|---|---|
| Flaw | An endpoint returns a user record by the id in the URL without checking who is asking |
| Class | Broken access control (insecure direct object reference), CWE-639, OWASP A01:2021 |
| Impact | Any caller can read any user's record by changing the id |
| Detection | Manual review, then a custom Semgrep rule |
| Fix | Compare the requested id with the authenticated user and return 403 on a mismatch |

## The flaw

The route reads a record using an id taken straight from the URL:

```python
@app.route("/users/<int:user_id>")
def get_user(user_id):
    return jsonify(USERS[user_id])
```

Nothing ties `user_id` to the caller. In this demo, authentication is a fake `X-User-Id` header handled by `current_user_id()`, so the code already knows who is calling and simply never uses that information.

| Request | Result before the fix |
|---|---|
| User 1 requests `/users/1` | 200, own record |
| User 1 requests `/users/2` | 200, **another user's record** |

## How to spot it in review

Questions to ask for any route that loads data by an identifier:

1. Where does the identifier come from, and can the caller choose it?
2. Who is the caller, and does the code ever compare the caller with the record's owner?
3. If the answer to the second question is no, does something outside this function (middleware or a policy layer) enforce it?

Here the answers are: the URL, yes, and no, and nothing outside the function checks either.

## Detection rule

`semgrep/flask-authz.yaml` flags a Flask route that looks up data by a function parameter (`$STORE[$ID]` or `$STORE.get($ID)`) unless the function first compares that parameter with `current_user_id()` and aborts on a mismatch.

The rule has test cases in `semgrep/flask-authz.py`: two vulnerable routes that must be flagged, one safe route and one unrelated route that must not be.

| Check | Result |
|---|---|
| `semgrep --test semgrep/` | All tests passed |
| Scan of the vulnerable app | 1 finding |
| Scan of the fixed app | 0 findings |

### Limits of the rule

- It is narrow. It knows one authorization helper name and one lookup pattern.
- It can miss the flaw when authorization happens in another function or a decorator, and it can flag code that is protected elsewhere.
- It supports a review. It does not replace one. Authorization is better enforced in one central place, backed by tests that try to read another user's data.

## The fix

```python
@app.route("/users/<int:user_id>")
def get_user(user_id):
    if user_id != current_user_id():
        abort(403)
    return jsonify(USERS[user_id])
```

| Request | Result after the fix |
|---|---|
| User 1 requests `/users/1` | 200, own record |
| User 1 requests `/users/2` | 403 |
| No `X-User-Id` header | 403 |

The fixed version also passes the rule scan with 0 findings.

## What I would do next in a real project

1. Add an automated test that requests another user's record and expects 403.
2. Move authorization into a shared decorator or policy layer so each route does not repeat the check.
3. Run the rule in CI so a regression is caught before it merges.
