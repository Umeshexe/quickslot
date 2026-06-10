import { NextResponse } from 'next/server';
import pool from '@/lib/db';

// GET /api/venues — list all venues
export async function GET() {
  try {
    const { rows } = await pool.query(
      `SELECT id, name, sport_type, location, price_inr FROM venues ORDER BY id`
    );
    return NextResponse.json(rows);
  } catch (err) {
    console.error('[GET /api/venues]', err);
    return NextResponse.json({ error: 'Failed to fetch venues' }, { status: 500 });
  }
}
