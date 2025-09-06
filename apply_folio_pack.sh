#!/usr/bin/env bash
set -euo pipefail
echo "== folio pack: auto-apply =="
ROOT="$(pwd)"
PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$PACK_DIR/files"

append_if_missing() {
  local marker="$1"
  local file="$2"
  local src_append="$3"
  if ! grep -q "$marker" "$file"; then
    echo -e "\n// --- folio-pack: appended ---" >> "$file"
    cat "$src_append" >> "$file"
    echo "appended to $file"
  else
    echo "marker '$marker' already found in $file (skipping append)"
  fi
}

copy_tree() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  rsync -a "$src"/ "$dst"/
  echo "copied $src -> $dst"
}

# 1) Prisma schema
echo "-> locating prisma schema.prisma ..."
SCHEMA_PATH=$(git ls-files | grep -E 'schema\.prisma$' | head -n1 || true)
if [ -z "$SCHEMA_PATH" ]; then
  SCHEMA_PATH=$(find . -type f -name schema.prisma -not -path "*/node_modules/*" | head -n1 || true)
fi

if [ -n "$SCHEMA_PATH" ]; then
  echo "   found: $SCHEMA_PATH"
  if ! grep -q "BEGIN: Ghostfolio Savings & Tax models" "$SCHEMA_PATH"; then
    cat "$SRC_DIR/prisma/schema.additions.prisma" >> "$SCHEMA_PATH"
    echo "   appended prisma additions."
  else
    echo "   prisma additions already present. skipping."
  fi
else
  echo "!! לא נמצא schema.prisma. הדבק ידנית את $SRC_DIR/prisma/schema.additions.prisma"
fi

# 2) Backend savings module
API_APP_DIR=$(git ls-files 'apps/*/src/app/app.module.ts' | grep 'apps/.*api.*/src/app/app.module.ts' | head -n1 || true)
if [ -n "$API_APP_DIR" ]; then
  API_BASE="$(dirname "$API_APP_DIR")"
  echo "-> backend app dir: $API_BASE"
  copy_tree "$SRC_DIR/backend/savings" "$API_BASE/savings"

  APP_MOD="$API_BASE/app.module.ts"
  if [ -f "$APP_MOD" ]; then
    if ! grep -q "@nestjs/schedule" "$APP_MOD"; then
      sed -i "1i import { ScheduleModule } from '@nestjs/schedule';" "$APP_MOD"
    fi
    if ! grep -q "SavingsModule" "$APP_MOD"; then
      sed -i "1i import { SavingsModule } from './savings/savings.module';" "$APP_MOD"
    fi
    if grep -q "imports:\s*\[" "$APP_MOD"; then
      sed -i "0,/imports:\s*\[/s//imports: [\n    ScheduleModule.forRoot(),\n    SavingsModule,/" "$APP_MOD" || true
    fi
    echo "   patched $APP_MOD"
  else
    echo "!! לא נמצא $APP_MOD – הוסף ידנית לפי files/backend/patches/app.module.snippet.ts"
  fi
else
  echo "!! לא נמצא apps/**api**/src/app/app.module.ts – העתק ידנית את התיקייה savings ל-backend שלך."
fi

# 3) Frontend savings + i18n
FRONT_APP_MOD=$(git ls-files 'apps/*/src/app/app.module.ts' | grep -v api | head -n1 || true)
if [ -n "$FRONT_APP_MOD" ]; then
  FRONT_APP_DIR="$(dirname "$FRONT_APP_MOD")"
  echo "-> frontend app dir: $FRONT_APP_DIR"

  copy_tree "$SRC_DIR/frontend/savings" "$FRONT_APP_DIR/savings"

  ASSETS_DIR=$(dirname "$FRONT_APP_DIR")/assets/i18n
  mkdir -p "$ASSETS_DIR"
  cp "$SRC_DIR/frontend/i18n/he.json" "$ASSETS_DIR/he.json"
  echo "   he.json -> $ASSETS_DIR"

  if ! grep -q "@ngx-translate/core" "$FRONT_APP_MOD"; then
    sed -i "1i import { HttpClientModule, HttpClient } from '@angular/common/http';" "$FRONT_APP_MOD"
    sed -i "1i import { TranslateModule, TranslateLoader } from '@ngx-translate/core';" "$FRONT_APP_MOD"
    sed -i "1i import { TranslateHttpLoader } from '@ngx-translate/http-loader';" "$FRONT_APP_MOD"
    sed -i "1i export function HttpLoaderFactory(http: HttpClient) { return new TranslateHttpLoader(http, '/assets/i18n/', '.json'); }" "$FRONT_APP_MOD"
    sed -i "0,/imports:\s*\[/s//imports: [\n    HttpClientModule,\n    TranslateModule.forRoot({ loader: { provide: TranslateLoader, useFactory: HttpLoaderFactory, deps: [HttpClient] } }),/" "$FRONT_APP_MOD" || true
    echo "   patched ngx-translate in app.module.ts"
  else
    echo "   ngx-translate נראה קיים. דילגתי."
  fi

  MAIN_TS=$(git ls-files 'apps/*/src/main.ts' | head -n1 || true)
  if [ -n "$MAIN_TS" ]; then
    if ! grep -q "TranslateService" "$MAIN_TS"; then
      cat >> "$MAIN_TS" <<'EOF'

// folio-pack: set default language to Hebrew
import { TranslateService } from '@ngx-translate/core';
import { registerLocaleData } from '@angular/common';
import localeHe from '@angular/common/locales/he';
registerLocaleData(localeHe);
platformBrowserDynamic().bootstrapModule(AppModule).then(moduleRef => {
  const translate = moduleRef.injector.get(TranslateService);
  translate.setDefaultLang('he');
  translate.use('he');
});
EOF
      echo "   appended Hebrew bootstrap to $MAIN_TS"
    fi
  else
    echo "!! לא נמצא main.ts – הוסף ידנית לפי files/frontend/patches/main.set-he.snippet.ts"
  fi

else
  echo "!! לא נמצא app.module.ts של ה-Frontend – העתק ידנית את רכיבי savings והוסף i18n לפי README."
fi

echo "== Done =="
echo "עכשיו הרץ: npx prisma generate && npx prisma migrate dev -n add_gf_savings_and_tax"
