import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { RegisterDto } from './dto/register.dto';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../database/schema';
import { users } from '../database/schema';
import * as bcrypt from 'bcrypt';
import { InferSelectModel, eq } from 'drizzle-orm';
import { JwtService } from '@nestjs/jwt';
import { LoginDto } from './dto/login.dto';

type User = InferSelectModel<typeof users>;

@Injectable()
export class AuthService {
  constructor(
    @InjectDrizzle() private db: LibSQLDatabase<typeof schema>,
    private jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    const { name, email, password } = registerDto;

    // Check if user exists
    const existingUser = await this.db
      .select()
      .from(users)
      .where(eq(users.email, email))
      .execute();

    if (existingUser.length > 0) {
      throw new ConflictException('E-mail já utilizado');
    }

    // Hash password
    const salt = await bcrypt.genSalt();
    const passwordHash = await bcrypt.hash(password, salt);

    // Create user
    await this.db
      .insert(users)
      .values({
        name,
        email,
        passwordHash,
        role: 'OWNER',
      })
      .execute();

    return { message: 'User registered successfully' };
  }

  async validateUser(
    email: string,
    pass: string,
  ): Promise<Omit<User, 'passwordHash'> | null> {
    const user = await this.db
      .select()
      .from(users)
      .where(eq(users.email, email))
      .execute();

    if (user.length > 0) {
      const isMatch = await bcrypt.compare(pass, user[0].passwordHash);
      if (isMatch) {
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const { passwordHash, ...result } = user[0];
        return result;
      }
    }
    return null;
  }

  async login(loginDto: LoginDto) {
    const user = await this.validateUser(loginDto.email, loginDto.password);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const payload = { email: user.email, sub: user.id, role: user.role };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }
}
