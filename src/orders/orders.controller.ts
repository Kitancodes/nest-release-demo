import { Controller, Get, NotFoundException, Param, ParseIntPipe } from '@nestjs/common';

// Added in v2.0.0
const ORDERS = [
  { id: 101, userId: 1, productId: 1, quantity: 1, status: 'delivered' },
  { id: 102, userId: 2, productId: 2, quantity: 2, status: 'shipped' },
  { id: 103, userId: 3, productId: 3, quantity: 1, status: 'processing' },
];

@Controller('api/orders')
export class OrdersController {
  @Get()
  findAll() {
    return { count: ORDERS.length, data: ORDERS };
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    const order = ORDERS.find((o) => o.id === id);
    if (!order) throw new NotFoundException(`Order ${id} not found`);
    return order;
  }
}
