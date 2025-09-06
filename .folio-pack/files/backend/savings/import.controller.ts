
import { Controller, Post, UploadedFile, UseInterceptors, Body, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ImportService } from './import.service';

@Controller('savings/import')
export class ImportController {
  constructor(private readonly svc: ImportService) {}

  @Post('csv')
  @UseInterceptors(FileInterceptor('file'))
  async importCsv(
    @UploadedFile() file: Express.Multer.File,
    @Body() map: {
      accountName: string;
      dateCol: string; amountCol: string; kindCol?: string; noteCol?: string;
      dateFormat?: string;
    }
  ) {
    if (!file?.buffer) throw new BadRequestException('קובץ CSV נדרש');
    const userId = 'CURRENT_USER';
    return this.svc.importCsv(userId, file, map);
  }
}
