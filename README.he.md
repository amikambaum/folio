
# folio – Direct Merge Pack
**Date:** 2025-08-31

חבילה זו מוסיפה ל־repo שלך:
- Backend: מודול `savings` (חיסכון/הפקדה חוזרת/יבוא CSV/דוחות/מס FIFO).
- Prisma: הרחבות סכימה.
- Frontend (Angular): רכיבי Savings + `he.json` לעברית.
- סקריפט `apply_folio_pack.sh` שמנסה להחיל הכל אוטומטית (כולל תיקוני app.module.ts ו-main.ts).

## שימוש מהיר
```bash
# בתוך תיקיית ה-repo שלך (root):
unzip folio-direct-merge-pack.zip -d ./.folio-pack
bash .folio-pack/apply_folio_pack.sh
```

לאחר מכן:
```bash
npm ci
npx prisma generate
npx prisma migrate dev -n add_gf_savings_and_tax   # לוקאלי; בשרת עדיף: npx prisma migrate deploy
git add .
git commit -m "feat: savings module + i18n he"
git push
```

אם יש לך GitHub Actions שמבנה Docker → המתן לסיום → עשה Recreate ל-container עם `Pull latest image`.
