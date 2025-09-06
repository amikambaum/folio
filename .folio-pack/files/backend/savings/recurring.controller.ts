
import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { RecurringService } from './recurring.service';

@Controller('savings/recurring')
export class RecurringController {
  constructor(private readonly svc: RecurringService) {}

  @Post()
  async create(@Body() dto: {
    accountId: string;
    amount: number;
    frequency: 'WEEKLY'|'MONTHLY'|'QUARTERLY';
    dayOfMonth?: number;
    weekday?: number;
    startDate: string;
    endDate?: string;
  }) {
    const userId = 'CURRENT_USER';
    return this.svc.create(userId, dto);
  }

  @Get(':accountId')
  async list(@Param('accountId') accountId: string) {
    const userId = 'CURRENT_USER';
    return this.svc.list(userId, accountId);
  }

  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Body() body: { isActive: boolean }) {
    const userId = 'CURRENT_USER';
    return this.svc.toggle(userId, id, body.isActive);
  }
}
