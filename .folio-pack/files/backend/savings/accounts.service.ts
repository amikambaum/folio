
import { Injectable } from '@nestjs/common';
import { SavingsPrismaService } from './savings.prisma';

@Injectable()
export class AccountsService {
  constructor(private readonly prisma: SavingsPrismaService) {}

  async create(userId: string, dto: any) {
    return this.prisma.gf_SavingsAccount.create({
      data: { userId, ...dto }
    });
  }

  async list(userId: string) {
    return this.prisma.gf_SavingsAccount.findMany({
      where: { userId, isActive: true },
      include: { recurringRules: true }
    });
  }
}
