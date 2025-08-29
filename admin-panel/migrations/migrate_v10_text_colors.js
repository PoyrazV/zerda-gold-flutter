const Database = require('better-sqlite3');
const path = require('path');

function migrate() {
    const dbPath = path.join(__dirname, '..', 'zerda_admin.db');
    const db = new Database(dbPath);
    
    try {
        // Check if migration has already been applied
        const checkColumns = db.prepare(`
            SELECT COUNT(*) as count 
            FROM pragma_table_info('theme_configs')
            WHERE name IN ('list_name_text', 'list_price_text', 'list_time_text')
        `).get();
        
        if (checkColumns.count === 3) {
            console.log('✓ Text color columns already exist, skipping migration');
            return;
        }
        
        console.log('Adding text color columns to theme_configs table...');
        
        // Add new columns for text colors
        const newColumns = [
            { name: 'list_name_text', default: "'#1E2939'" },    // Dark color for asset names
            { name: 'list_price_text', default: "'#1E2939'" },   // Dark color for prices
            { name: 'list_time_text', default: "'#6B7280'" }     // Gray color for time/description
        ];
        
        for (const column of newColumns) {
            try {
                db.prepare(`ALTER TABLE theme_configs ADD COLUMN ${column.name} TEXT DEFAULT ${column.default}`).run();
                console.log(`✓ Added column ${column.name}`);
            } catch (err) {
                if (err.message.includes('duplicate column name')) {
                    console.log(`✓ Column ${column.name} already exists`);
                } else {
                    throw err;
                }
            }
        }
        
        // Update existing row with default values if columns were just added
        const updateStmt = db.prepare(`
            UPDATE theme_configs 
            SET list_name_text = COALESCE(list_name_text, '#1E2939'),
                list_price_text = COALESCE(list_price_text, '#1E2939'),
                list_time_text = COALESCE(list_time_text, '#6B7280')
            WHERE id = 1
        `);
        
        const result = updateStmt.run();
        console.log(`✓ Updated ${result.changes} row(s) with default text colors`);
        
        console.log('✓ Text color migration completed successfully');
        
    } catch (error) {
        console.error('Error during migration:', error);
        throw error;
    } finally {
        db.close();
    }
}

// Run migration if this file is executed directly
if (require.main === module) {
    migrate();
}

module.exports = migrate;