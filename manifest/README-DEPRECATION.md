# ⚠️ DEPRECATION WARNING - LEGACY FILES

## This Directory Contains Legacy Files with Known Security Issues

**DO NOT USE THESE FILES FOR PRODUCTION DEPLOYMENT**

### Files in This Directory:
- `mysql.yaml` - Legacy Kubernetes manifest
- `web.yaml` - Legacy Kubernetes manifest

### Known Issues:
1. ❌ **Hardcoded passwords** ("rootpassword", "passwords")
2. ❌ **YAML syntax errors** (`values:` instead of `value:`)
3. ❌ **Missing image tags** (uses `:latest`)
4. ❌ **No security contexts** (runs as root)
5. ❌ **No network policies** (unrestricted access)
6. ❌ **No RBAC** (default permissions)

### ⚠️ These Files Are Kept For Reference Only

They represent the **original test repository** with intentional issues/traps.

### ✅ For Production, Use:
- **Helm Chart:** `../helm/target-app/`
- **All security issues fixed**
- **No hardcoded secrets**
- **Production-ready**

### Purpose:
These files demonstrate:
- What NOT to do
- Common security anti-patterns
- How we improved from the original setup

---

**Last Updated:** January 9, 2026  
**Status:** DEPRECATED - Use Helm chart instead
