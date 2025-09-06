
import { Injectable } from '@nestjs/common';
import { SavingsPrismaService } from './savings.prisma';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: SavingsPrismaService) {}

  async getReport(userId: string, params: { period:'MONTH'|'QUARTER'|'YEAR'; year?: number; month?: number }) {
    const accounts = await this.prisma.gf_SavingsAccount.findMany({ where: { userId, isActive: true }});
    const accIds = accounts.map(a => a.id);
    const tx = await this.prisma.gf_SavingsTx.findMany({
      where: { accountId: { in: accIds } },
      orderBy: { date: 'asc' },
    });

    const buckets: Record<string, number> = {};
    for (const t of tx) {
      const d = new Date(t.date);
      let key = `${d.getFullYear()}-M${d.getMonth()+1}`;
      if (params.period === 'YEAR') key = `${d.getFullYear()}`;
      if (params.period === 'QUARTER') key = `${d.getFullYear()}-Q${Math.floor(d.getMonth()/3)+1}`;
      buckets[key] = (buckets[key] || 0) + Number(t.amount) * (t.kind === 'WITHDRAWAL' ? -1 : 1);
    }

    const labels = Object.keys(buckets).sort();
    const values = labels.map(k => buckets[k]);

    return { period: params.period, labels, values, total: values.reduce((a,b)=>a+b,0) };
  }
}
