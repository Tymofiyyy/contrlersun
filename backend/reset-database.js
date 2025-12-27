// reset-database.js - ВИПРАВЛЕНА ВЕРСІЯ без конфліктів
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'iot_user',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'iot_devices',
  password: process.env.DB_PASSWORD || 'Tomwoker159357',
  port: process.env.DB_PORT || 5432,
});

async function resetDatabase() {
  const client = await pool.connect();
  
  try {
    console.log('🗑️  Видаляємо старі таблиці...');
    
    // Видаляємо таблиці в правильному порядку
    await client.query('DROP TABLE IF EXISTS energy_mode_history CASCADE');
    await client.query('DROP TABLE IF EXISTS energy_schedules CASCADE');
    await client.query('DROP TABLE IF EXISTS device_energy_modes CASCADE');
    await client.query('DROP TABLE IF EXISTS daily_energy CASCADE');
    await client.query('DROP TABLE IF EXISTS energy_data CASCADE');
    await client.query('DROP TABLE IF EXISTS device_history CASCADE');
    await client.query('DROP TABLE IF EXISTS user_devices CASCADE');
    await client.query('DROP TABLE IF EXISTS devices CASCADE');
    await client.query('DROP TABLE IF EXISTS users CASCADE');
    
    console.log('✅ Старі таблиці видалено');
    
    console.log('🏗️  Створюємо нові таблиці...');
    
    // Користувачі
    await client.query(`
      CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        google_id VARCHAR(255) UNIQUE NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        name VARCHAR(255),
        picture TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Таблиця users створена');
    
    // Пристрої
    await client.query(`
      CREATE TABLE devices (
        id SERIAL PRIMARY KEY,
        device_id VARCHAR(255) UNIQUE NOT NULL,
        name VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Таблиця devices створена');
    
    // Зв'язок користувач-пристрій
    await client.query(`
      CREATE TABLE user_devices (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        device_id INTEGER REFERENCES devices(id) ON DELETE CASCADE,
        is_owner BOOLEAN DEFAULT false,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, device_id)
      )
    `);
    console.log('✅ Таблиця user_devices створена');
    
    // Історія пристроїв
    await client.query(`
      CREATE TABLE device_history (
        id SERIAL PRIMARY KEY,
        device_id VARCHAR(255),
        relay_state BOOLEAN,
        wifi_rssi INTEGER,
        uptime INTEGER,
        free_heap INTEGER,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Таблиця device_history створена');
    
    // Енергетичні дані
    await client.query(`
      CREATE TABLE energy_data (
        id SERIAL PRIMARY KEY,
        device_id VARCHAR(255) NOT NULL,
        power_kw DECIMAL(10,3) NOT NULL DEFAULT 0,
        energy_kwh DECIMAL(12,3) NOT NULL DEFAULT 0,
        timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        created_at DATE NOT NULL DEFAULT CURRENT_DATE
      )
    `);
    console.log('✅ Таблиця energy_data створена');
    
    // Денна енергія
    await client.query(`
      CREATE TABLE daily_energy (
        id SERIAL PRIMARY KEY,
        device_id VARCHAR(255) NOT NULL,
        date DATE NOT NULL,
        total_energy_kwh DECIMAL(10,3) NOT NULL,
        max_power_kw DECIMAL(10,3),
        avg_power_kw DECIMAL(10,3),
        data_points INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT daily_energy_unique UNIQUE (device_id, date)
      )
    `);
    console.log('✅ Таблиця daily_energy створена');
    
    // Режими енергії
    await client.query(`
      CREATE TABLE device_energy_modes (
        id SERIAL PRIMARY KEY,
        device_id VARCHAR(255) UNIQUE NOT NULL,
        current_mode VARCHAR(50) NOT NULL DEFAULT 'solar',
        last_changed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        changed_by VARCHAR(50) DEFAULT 'manual',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT valid_energy_mode CHECK (current_mode IN ('solar', 'grid'))
      )
    `);
    console.log('✅ Таблиця device_energy_modes створена');
    
    // Розклади
    await client.query(`
      CREATE TABLE energy_schedules (
        id SERIAL PRIMARY KEY,
        device_id VARCHAR(255) NOT NULL,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        target_mode VARCHAR(50) NOT NULL,
        hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
        minute INTEGER NOT NULL CHECK (minute >= 0 AND minute <= 59),
        repeat_type VARCHAR(50) NOT NULL DEFAULT 'once',
        repeat_days INTEGER[] DEFAULT NULL,
        is_enabled BOOLEAN DEFAULT true,
        last_executed TIMESTAMP DEFAULT NULL,
        next_execution TIMESTAMP DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT valid_target_mode CHECK (target_mode IN ('solar', 'grid')),
        CONSTRAINT valid_repeat_type CHECK (repeat_type IN ('once', 'daily', 'weekly', 'weekdays', 'weekends'))
      )
    `);
    console.log('✅ Таблиця energy_schedules створена');
    
    // Історія перемикань
    await client.query(`
      CREATE TABLE energy_mode_history (
        id SERIAL PRIMARY KEY,
        device_id VARCHAR(255) NOT NULL,
        from_mode VARCHAR(50),
        to_mode VARCHAR(50) NOT NULL,
        changed_by VARCHAR(50) NOT NULL,
        schedule_id INTEGER REFERENCES energy_schedules(id) ON DELETE SET NULL,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT valid_from_mode CHECK (from_mode IN ('solar', 'grid', NULL)),
        CONSTRAINT valid_to_mode CHECK (to_mode IN ('solar', 'grid'))
      )
    `);
    console.log('✅ Таблиця energy_mode_history створена');
    
    // Створюємо індекси (БЕЗ DROP IF EXISTS)
    console.log('📇 Створюємо індекси...');
    
    await client.query('CREATE INDEX idx_users_google_id ON users(google_id)');
    await client.query('CREATE INDEX idx_users_email ON users(email)');
    await client.query('CREATE INDEX idx_devices_device_id ON devices(device_id)');
    await client.query('CREATE INDEX idx_device_history_device_id_timestamp ON device_history(device_id, timestamp DESC)');
    await client.query('CREATE INDEX idx_user_devices_user_id ON user_devices(user_id)');
    await client.query('CREATE INDEX idx_user_devices_device_id ON user_devices(device_id)');
    
    // Індекси для енергії
    await client.query('CREATE INDEX idx_energy_data_device_id ON energy_data(device_id)');
    await client.query('CREATE INDEX idx_energy_data_timestamp ON energy_data(timestamp DESC)');
    await client.query('CREATE INDEX idx_energy_data_device_timestamp ON energy_data(device_id, timestamp DESC)');
    await client.query('CREATE INDEX idx_energy_data_created_at ON energy_data(created_at DESC)');
    await client.query('CREATE INDEX idx_daily_energy_device_id ON daily_energy(device_id)');
    await client.query('CREATE INDEX idx_daily_energy_date ON daily_energy(date DESC)');
    
    // Індекси для режимів
    await client.query('CREATE INDEX idx_energy_modes_device_id ON device_energy_modes(device_id)');
    await client.query('CREATE INDEX idx_schedules_device_id ON energy_schedules(device_id)');
    await client.query('CREATE INDEX idx_schedules_user_id ON energy_schedules(user_id)');
    await client.query('CREATE INDEX idx_schedules_enabled ON energy_schedules(is_enabled)');
    await client.query('CREATE INDEX idx_schedules_next_execution ON energy_schedules(next_execution)');
    await client.query('CREATE INDEX idx_history_device_id ON energy_mode_history(device_id)');
    await client.query('CREATE INDEX idx_history_timestamp ON energy_mode_history(timestamp DESC)');
    
    console.log('✅ Індекси створено');
    
    // Функція для розрахунку наступного виконання
    await client.query(`
      CREATE OR REPLACE FUNCTION calculate_next_execution(
        p_hour INTEGER,
        p_minute INTEGER,
        p_repeat_type VARCHAR,
        p_repeat_days INTEGER[],
        p_from_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) RETURNS TIMESTAMP AS $$
      DECLARE
        v_next_time TIMESTAMP;
        v_current_dow INTEGER;
        v_target_dow INTEGER;
        v_days_ahead INTEGER;
      BEGIN
        v_next_time := DATE_TRUNC('day', p_from_time) + 
                       MAKE_INTERVAL(hours => p_hour, mins => p_minute);
        
        IF v_next_time <= p_from_time THEN
          v_next_time := v_next_time + INTERVAL '1 day';
        END IF;
        
        IF p_repeat_type = 'once' THEN
          RETURN v_next_time;
        END IF;
        
        IF p_repeat_type = 'daily' THEN
          RETURN v_next_time;
        END IF;
        
        IF p_repeat_type = 'weekdays' THEN
          WHILE EXTRACT(DOW FROM v_next_time) IN (0, 6) LOOP
            v_next_time := v_next_time + INTERVAL '1 day';
          END LOOP;
          RETURN v_next_time;
        END IF;
        
        IF p_repeat_type = 'weekends' THEN
          WHILE EXTRACT(DOW FROM v_next_time) NOT IN (0, 6) LOOP
            v_next_time := v_next_time + INTERVAL '1 day';
          END LOOP;
          RETURN v_next_time;
        END IF;
        
        IF p_repeat_type = 'weekly' AND p_repeat_days IS NOT NULL THEN
          v_current_dow := EXTRACT(DOW FROM v_next_time)::INTEGER;
          
          FOR v_target_dow IN SELECT UNNEST(p_repeat_days) ORDER BY 1 LOOP
            v_days_ahead := (v_target_dow - v_current_dow + 7) % 7;
            
            IF v_days_ahead = 0 AND v_next_time > p_from_time THEN
              RETURN v_next_time;
            ELSIF v_days_ahead > 0 THEN
              RETURN v_next_time + (v_days_ahead || ' days')::INTERVAL;
            END IF;
          END LOOP;
          
          v_target_dow := p_repeat_days[1];
          v_days_ahead := (v_target_dow - v_current_dow + 7) % 7;
          IF v_days_ahead = 0 THEN
            v_days_ahead := 7;
          END IF;
          RETURN v_next_time + (v_days_ahead || ' days')::INTERVAL;
        END IF;
        
        RETURN v_next_time;
      END;
      $$ LANGUAGE plpgsql;
    `);
    
    // Тригер
    await client.query(`
      CREATE OR REPLACE FUNCTION update_next_execution()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.is_enabled = true THEN
          NEW.next_execution := calculate_next_execution(
            NEW.hour,
            NEW.minute,
            NEW.repeat_type,
            NEW.repeat_days,
            COALESCE(NEW.last_executed, CURRENT_TIMESTAMP)
          );
        ELSE
          NEW.next_execution := NULL;
        END IF;
        
        NEW.updated_at := CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);
    
    await client.query(`
      DROP TRIGGER IF EXISTS trigger_update_next_execution ON energy_schedules;
    `);
    
    await client.query(`
      CREATE TRIGGER trigger_update_next_execution
      BEFORE INSERT OR UPDATE ON energy_schedules
      FOR EACH ROW
      EXECUTE FUNCTION update_next_execution();
    `);
    
    console.log('✅ Функції та тригери створено');
    
    console.log('\n✅ База даних успішно створена з підтримкою режимів енергії!');
    
  } catch (error) {
    console.error('❌ Помилка:', error.message);
    process.exit(1);
  } finally {
    client.release();
    pool.end();
  }
}

resetDatabase();