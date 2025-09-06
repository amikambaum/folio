
import { Module } from '@nestjs/common';
import { AccountsController } from './accounts.controller';
import { RecurringController } from './recurring.controller';
import { ImportController } from './import.controller';
import { ReportsController } from './reports.controller';
import { TaxController } from './tax.controller';
import { AccountsService } from './accounts.service';
import { RecurringService } from './recurring.service';
import { ImportService } from './import.service';
import { ReportsService } from './reports.service';
import { TaxService } from './tax.service';
import { SavingsCron } from './savings.cron';
import { SavingsPrismaService } from './savings.prisma';

@Module({
  controllers: [
    AccountsController,
    RecurringController,
    ImportController,
    ReportsController,
    TaxController,
  ],
  providers: [
    SavingsPrismaService,
    AccountsService,
    RecurringService,
    ImportService,
    ReportsService,
    TaxService,
    SavingsCron,
  ],
})
export class SavingsModule {}
