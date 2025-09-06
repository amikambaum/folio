
import { Controller, Get, Query } from '@nestjs/common';
import { TaxService } from './tax.service';

@Controller('savings/tax')
export class TaxController {
  constructor(private readonly svc: TaxService) {}

  @Get('estimate')
  async estimate(@Query('year') year: string) {
    const userId = 'CURRENT_USER';
    return this.svc.estimate(userId, Number(year));
  }
}
