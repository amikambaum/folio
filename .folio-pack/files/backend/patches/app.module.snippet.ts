// Add to apps/api/src/app/app.module.ts
import { ScheduleModule } from '@nestjs/schedule';
import { SavingsModule } from './savings/savings.module';
// In @Module imports: [ ScheduleModule.forRoot(), SavingsModule, ... ]
