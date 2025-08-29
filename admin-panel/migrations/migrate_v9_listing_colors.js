const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'zerda_admin.db');

console.log('🎨 Running migration v9: Adding listing color columns...');

const db = new sqlite3.Database(DB_PATH);

db.serialize(() => {
    // Check if columns already exist
    db.all("PRAGMA table_info(theme_configs)", (err, columns) => {
        if (err) {
            console.error('❌ Error checking table info:', err);
            db.close();
            return;
        }

        const existingColumns = columns.map(col => col.name);
        const newColumns = [
            { name: 'list_primary_color', default: "'#ECFDF5'" },
            { name: 'list_primary_border', default: "'#059669'" },
            { name: 'list_primary_text', default: "'#047857'" },
            { name: 'list_secondary_color', default: "'#FEF2F2'" },
            { name: 'list_secondary_border', default: "'#DC2626'" },
            { name: 'list_secondary_text', default: "'#B91C1C'" },
            { name: 'list_row_even', default: "'#F0F0F0'" },
            { name: 'list_row_odd', default: "'#FFFFFF'" }
        ];

        const columnsToAdd = newColumns.filter(col => !existingColumns.includes(col.name));

        if (columnsToAdd.length === 0) {
            console.log('✅ All listing color columns already exist');
            db.close();
            return;
        }

        // Add new columns
        let completed = 0;
        columnsToAdd.forEach(column => {
            db.run(`ALTER TABLE theme_configs ADD COLUMN ${column.name} TEXT DEFAULT ${column.default}`, (err) => {
                if (err) {
                    console.error(`❌ Error adding column ${column.name}:`, err);
                } else {
                    console.log(`✅ Added column: ${column.name}`);
                }
                
                completed++;
                if (completed === columnsToAdd.length) {
                    console.log('🎨 Migration v9 completed successfully!');
                    
                    // Update existing records with default values
                    db.run(`UPDATE theme_configs SET 
                        list_primary_color = COALESCE(list_primary_color, '#ECFDF5'),
                        list_primary_border = COALESCE(list_primary_border, '#059669'),
                        list_primary_text = COALESCE(list_primary_text, '#047857'),
                        list_secondary_color = COALESCE(list_secondary_color, '#FEF2F2'),
                        list_secondary_border = COALESCE(list_secondary_border, '#DC2626'),
                        list_secondary_text = COALESCE(list_secondary_text, '#B91C1C'),
                        list_row_even = COALESCE(list_row_even, '#F0F0F0'),
                        list_row_odd = COALESCE(list_row_odd, '#FFFFFF')
                    `, (err) => {
                        if (err) {
                            console.error('❌ Error updating existing records:', err);
                        } else {
                            console.log('✅ Updated existing records with default values');
                        }
                        db.close();
                    });
                }
            });
        });
    });
});