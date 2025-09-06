
import { Body, Controller, Get, Post } from '@nestjs/common';
import { AccountsService } from './accounts.service';

@Controller('savings/accounts')
export class AccountsController {
  constructor(private readonly svc: AccountsService) {}

  @Post()
  async create(@Body() dto: {
    name: string;
    kind: 'FIXED'|'VARIABLE'|'PRIME_PLUS_MINUS';
    annualRateBps?: number;
    baseIndex?: 'P'|'CPI'|'EURIBOR'|'SOFR';
    marginBps?: number;
    compounding: 'NONE'|'MONTHLY'|'YEARLY';
    currency?: string;
  }) {
    const userId = 'CURRENT_USER';
    return this.svc.create(userId, dto);
  }

  @Get()
  async list() {
    const userId = 'CURRENT_USER';
    return this.svc.list(userId);
  }
}
