
import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { SavingsPrismaService } from './savings.prisma';
import { addDays, addMonths } from 'date-fns';

@Injectable()
export class RecurringService {
  constructor(private readonly prisma: SavingsPrismaService) {}

  async create(userId: string, dto: any) {
    const acc = await this.prisma.gf_SavingsAccount.findUnique({ where: { id: dto.accountId }});
    if (!acc) throw new NotFoundException('החשבון לא נמצא');
    if (acc.userId !== userId) throw new ForbiddenException('גישה נדחתה');

    const start = new Date(dto.startDate);
    let next = start;
    if (dto.frequency === 'WEEKLY') next = addDays(start, 7);
    if (dto.frequency === 'MONTHLY') next = addMonths(start, 1);
    if (dto.frequency === 'QUARTERLY') next = addMonths(start, 3);

    return this.prisma.gf_RecurringDeposit.create({
      data: {
        accountId: dto.accountId,
        amount: dto.amount,
        frequency: dto.frequency,
        dayOfMonth: dto.dayOfMonth ?? null,
        weekday: dto.weekday ?? null,
        startDate: start,
        endDate: dto.endDate ? new Date(dto.endDate) : null,
        nextRunAt: next,
      }
    });
  }

  async list(userId: string, accountId: string) {
    const acc = await this.prisma.gf_SavingsAccount.findUnique({ where: { id: accountId }});
    if (!acc) throw new NotFoundException('החשבון לא נמצא');
    if (acc.userId !== userId) throw new ForbiddenException('גישה נדחתה');
    return this.prisma.gf_RecurringDeposit.findMany({ where: { accountId }});
  }

  async toggle(userId: string, id: string, isActive: boolean) {
    const rec = await this.prisma.gf_RecurringDeposit.findUnique({ where: { id }, include: { account: true }});
    if (!rec) throw new NotFoundException('Rule not found');
    if (rec.account.userId !== userId) throw new ForbiddenException('גישה נדחתה');
    return this.prisma.gf_RecurringDeposit.update({ where: { id }, data: { isActive }});
  }
}
