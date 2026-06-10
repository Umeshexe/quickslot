import { NextRequest, NextResponse } from 'next/server';
import pool from '@/lib/db';

// DELETE /api/bookings/[id] — cancel a booking
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const bookingId = parseInt(id, 10);
  const userId = request.headers.get('x-user-id');

  if (!userId) {
    return NextResponse.json({ error: 'X-User-Id header is required' }, { status: 401 });
  }

  if (isNaN(bookingId)) {
    return NextResponse.json({ error: 'Invalid booking id' }, { status: 400 });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Ensure the booking belongs to the requesting user
    const { rows } = await client.query(
      'SELECT id, slot_id, user_id FROM bookings WHERE id = $1 FOR UPDATE',
      [bookingId]
    );

    if (rows.length === 0) {
      await client.query('ROLLBACK');
      return NextResponse.json({ error: 'Booking not found' }, { status: 404 });
    }

    if (rows[0].user_id !== userId) {
      await client.query('ROLLBACK');
      return NextResponse.json({ error: 'Forbidden: not your booking' }, { status: 403 });
    }

    const slotId = rows[0].slot_id;

    // Delete booking and free the slot back to available
    await client.query('DELETE FROM bookings WHERE id = $1', [bookingId]);
    await client.query("UPDATE slots SET status = 'available' WHERE id = $1", [slotId]);

    await client.query('COMMIT');
    return NextResponse.json({ message: 'Booking cancelled' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`[DELETE /api/bookings/${id}]`, err);
    return NextResponse.json({ error: 'Cancellation failed' }, { status: 500 });
  } finally {
    client.release();
  }
}
