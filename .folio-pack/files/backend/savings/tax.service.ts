
import { Injectable } from '@nestjs/common';
import { SavingsPrismaService } from './savings.prisma';

type Trade = { symbol: string; qty: number; price: number; when: Date; side: 'BUY'|'SELL'; fee?: number; lotRef?: string };

@Injectable()
export class TaxService {
  constructor(private readonly prisma: SavingsPrismaService) {}

  async estimate(userId: string, year: number) {
    const settings = await this.prisma.gf_TaxSettings.upsert({
      where: { userId },
      create: { userId, country: 'IL', rateBps: 2500 },
      update: {}
    });

    const trades: Trade[] = []; // TODO: שלוף מן המערכת האמיתית לפי השנה

    const lots: { symbol: string; qty: number; cost: number; when: Date; lotRef?: string }[] = [];
    let realizedGain = 0;

    trades.sort((a,b)=>+a.when - +b.when);

    for (const t of trades) {
      if (t.side === 'BUY') {
        lots.push({ symbol: t.symbol, qty: t.qty, cost: t.qty * t.price + (t.fee||0), when: t.when, lotRef: t.lotRef });
      } else {
        let qtyToClose = t.qty;
        const relevant = settings.lotMethod === 'SPECIFIC_ID'
          ? lots.filter(l => l.symbol===t.symbol && l.lotRef===t.lotRef && l.qty>0)
          : lots.filter(l => l.symbol===t.symbol && l.qty>0).sort((a,b)=>+a.when - +b.when);

        for (const l of relevant) {
          if (qtyToClose <= 0) break;
          const closeQty = Math.min(l.qty, qtyToClose);
          const avgCost = l.cost / l.qty;
          const proceeds = closeQty * t.price - (t.fee||0)/t.qty*closeQty;
          const costPortion = closeQty * avgCost;
          realizedGain += (proceeds - costPortion);
          l.qty -= closeQty;
          l.cost -= costPortion;
          qtyToClose -= closeQty;
        }
      }
    }

    const tax = realizedGain > 0 ? (realizedGain * settings.rateBps) / 10000 : 0;
    return { year, realizedGain, taxRateBps: settings.rateBps, estimatedTax: tax };
  }
}
