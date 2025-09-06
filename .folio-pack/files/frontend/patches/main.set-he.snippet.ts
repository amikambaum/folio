// In apps/<frontend>/src/main.ts after bootstrap:
import { TranslateService } from '@ngx-translate/core';
import { registerLocaleData } from '@angular/common';
import localeHe from '@angular/common/locales/he';
registerLocaleData(localeHe);
platformBrowserDynamic().bootstrapModule(AppModule).then(moduleRef => {
  const translate = moduleRef.injector.get(TranslateService);
  translate.setDefaultLang('he');
  translate.use('he');
});
