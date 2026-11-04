import { Controller, Get, NotFoundException, Param, ParseIntPipe } from '@nestjs/common';

const PRODUCTS = [
  { id: 1, name: 'Laptop', price: 1200, currency: 'USD' },
  { id: 2, name: 'Headphones', price: 150, currency: 'USD' },
  { id: 3, name: 'Keyboard', price: 80, currency: 'USD' },
];

@Controller('api/products')
export class ProductsController {
  @Get()
  findAll() {
    return { count: PRODUCTS.length, data: PRODUCTS };
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    const product = PRODUCTS.find((p) => p.id === id);
    if (!product) throw new NotFoundException(`Product ${id} not found`);
    return product;
  }
}
