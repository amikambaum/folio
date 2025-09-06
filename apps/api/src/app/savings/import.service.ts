
import { Injectable, NotFoundException } from '@nestjs/common';
import { SavingsPrismaService } from './savings.prisma';
import { parse } from 'csv-parse/sync';
import * as dayjs from 'dayjs';

@Injectable()
export class ImportService {
  constructor(private readonly prisma: SavingsPrismaService) {}

  async importCsv(userId: string, file: Express.Multer.File, map: any) {
    const rows = parse(file.buffer, { columns: true, skip_empty_lines: true });

    const acc = await this.prisma.gf_SavingsAccount.findFirst({
      where: { userId, name: map.accountName }
    });
    if (!acc) throw new NotFoundException('החשבון לא נמצא');

    const txData = rows.map((r: any) => ({
      accountId: acc.id,
      date: dayjs(r[map.dateCol], map.dateFormat || 'YYYY-MM-DD').toDate(),
      kind: (r[map.kindCol] || 'DEPOSIT').toUpperCase(),
      amount: r[map.amountCol],
      note: map.noteCol ? r[map.noteCol] : null
    }));

    await this.prisma.$transaction(
      txData.map((t) => this.prisma.gf_SavingsTx.create({ data: t }))
    );

    return { imported: txData.length };
  }
}
