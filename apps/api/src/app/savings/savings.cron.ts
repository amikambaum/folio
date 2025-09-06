
import { Cron, CronExpression } from '@nestjs/schedule';
import { Injectable } from '@nestjs/common';
import { SavingsPrismaService } from './savings.prisma';
import { addDays, addMonths } from 'date-fns';

@Injectable()
export class SavingsCron {
  constructor(private readonly prisma: SavingsPrismaService) {}

  @Cron(CronExpression.EVERY_30_MINUTES)
  async runRecurring() {
    const now = new Date();
    const due = await this.prisma.gf_RecurringDeposit.findMany({
      where: { isActive: true, nextRunAt: { lte: now } },
      include: { account: true }
    });

    for (const r of due) {
      await this.prisma.$transaction(async (tx) => {
        await tx.gf_SavingsTx.create({
          data: {
            accountId: r.accountId,
            date: now,
            kind: 'DEPOSIT',
            amount: r.amount,
          }
        });

        let next = now;
        if (r.frequency === 'WEEKLY') next = addDays(now, 7);
        if (r.frequency === 'MONTHLY') next = addMonths(now, 1);
        if (r.frequency === 'QUARTERLY') next = addMonths(now, 3);

        await tx.gf_RecurringDeposit.update({
          where: { id: r.id },
          data: { nextRunAt: next }
        });
      });
    }
  }
}
