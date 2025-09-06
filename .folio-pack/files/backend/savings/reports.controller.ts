
import { Controller, Get, Query } from '@nestjs/common';
import { ReportsService } from './reports.service';

@Controller('savings/reports')
export class ReportsController {
  constructor(private readonly svc: ReportsService) {}

  @Get()
  async getReport(@Query('period') period: 'MONTH'|'QUARTER'|'YEAR',
                  @Query('year') year?: string,
                  @Query('month') month?: string) {
    const userId = 'CURRENT_USER';
    return this.svc.getReport(userId, { period, year: Number(year), month: Number(month) });
  }
}
