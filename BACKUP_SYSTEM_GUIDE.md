# Food Runs Counter - Data Backup System

## Overview
The new backup system protects all your valuable restaurant data from being lost during app updates or device issues.

## Features

### 🔄 **Full Data Backup**
- **Server Information**: Names, team colors, IDs
- **Run Totals**: All-time run counts per server
- **Shift History**: Complete record of all shifts with detailed counts
- **Server Profiles**: Achievements, avatars, MVP records, performance stats
- **App Settings**: Gamification settings, wallpapers, preferences
- **Day Plans**: Roster assignments and scheduling data
- **Performance Data**: Tap timing logs and analytics

### 📱 **Easy Access**
- Available from Admin Settings (Settings → Admin → "Data Backup & Restore")
- Protected by admin PIN for security
- Intuitive interface with clear actions
- Visual backup management with file details

### 💾 **Backup Types**
1. **Quick Backup**: Instant backup with timestamp
2. **Named Backup**: Custom backup with your chosen name (e.g., "before_update_v2")

### 🔒 **Safe Restoration**
- Automatic backup of current data before restoring
- Complete data validation before restoration
- Clear warnings about data replacement
- Rollback capability if needed

## How to Use

### Creating Backups

1. **Access Backup Manager**:
   - Go to Settings (three dots menu)
   - Select "Settings"
   - Tap "Admin" and enter PIN (5520)
   - Select "Data Backup & Restore"

2. **Quick Backup**:
   - Tap "Quick Backup" button
   - Backup created with timestamp filename

3. **Named Backup**:
   - Tap "Named Backup" button
   - Enter a meaningful name (e.g., "before_roster_change")
   - Tap "Create"
   - Custom backup saved with your name

### Restoring Data

1. **Select Backup**:
   - Browse available backups in the list
   - View creation date and file size
   - Tap the menu button (⋮) on any backup

2. **Restore Process**:
   - Select "Restore" from menu
   - Review the warning dialog carefully
   - Confirm restoration
   - Wait for completion message
   - App data automatically reloads

### Managing Backups

- **View Details**: Each backup shows creation date, size, and version
- **Delete Backups**: Remove old backups to save space
- **Automatic Protection**: Current data backed up before any restoration

## Best Practices

### 📅 **Regular Backups**
- Create backups before app updates
- Weekly backups during heavy usage periods
- Before making major roster changes
- Before device maintenance/replacement

### 🏷️ **Naming Convention**
Use descriptive names for important backups:
- `before_update_v3`
- `end_of_week_backup`
- `roster_change_jan_2025`
- `milestone_1000_runs`

### 🧹 **Backup Management**
- Keep recent backups (last 2-3 weeks)
- Delete very old backups to save storage
- Keep milestone backups (monthly/quarterly)

## Storage Information

- **Location**: App documents directory
- **Format**: Human-readable JSON files
- **Typical Size**: 50KB - 2MB depending on data amount
- **Compatibility**: Forward and backward compatible within app versions

## Recovery Scenarios

### 📱 **App Update Issues**
1. Create backup before updating
2. If data lost after update, restore from backup
3. All data returns to exact previous state

### 🔄 **Device Transfer**
1. Create backup on old device
2. Export/share backup file if needed
3. Install app on new device
4. Import and restore backup file

### 🚨 **Accidental Data Loss**
1. Restore from most recent backup
2. Review restored data
3. Continue normal operations

## Technical Details

- **Data Integrity**: Full validation during backup/restore
- **Error Handling**: Comprehensive error messages and recovery
- **Performance**: Optimized for large datasets
- **Security**: Local storage only, no cloud transmission

## Troubleshooting

### ❌ **Backup Creation Failed**
- Check available storage space
- Ensure app has file permissions
- Try again after closing/reopening app

### ❌ **Restore Failed**
- Verify backup file isn't corrupted
- Check backup file format version
- Contact support if issues persist

### ⚠️ **Large Backup Files**
- Normal for extensive shift history
- Consider archiving old data if storage is limited
- Large files may take longer to backup/restore

## Support

If you encounter issues with the backup system:
1. Note the exact error message
2. Try the operation again
3. Check available storage space
4. Document steps that led to the problem

Remember: The backup system is your insurance policy against data loss. Use it regularly to keep your valuable restaurant data safe!
