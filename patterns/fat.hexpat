
namespace FAT16 {

    u64 bytesPerCluster;
    
    u64 FATStart;
    u64 FATSize;

    u64 rootDirStart;
    u64 dataStart;

    struct FAT_BootSector {
        char    jmpBoot[3];           // Jump instruction
        char    OEMName[8];           // OEM Name
        le u16  BytesPerSector;       // Bytes per sector
        u8      SectorsPerCluster;    // Sectors per cluster
        le u16  ReservedSectors;      // Reserved sectors
        u8      FATCount;             // Number of FATs
        le u16  RootEntryCount;       // Max root directory entries (FAT12/16)
        le u16  TotalSectors16;       // Total sectors (if 0, check LargeSectors)
        u8      MediaDescriptor;      // Media descriptor type
        le u16  SectorsPerFAT16;      // Sectors per FAT (FAT12/16)
        le u16  SectorsPerTrack;      // Sectors per track (for CHS)
        le u16  HeadsPerCylinder;     // Number of heads (for CHS)
        le u32  HiddenSectors;        // Hidden sectors before FAT
        le u32  TotalSectors32;       // Large sector count
        u8      DriveNumber;         // BIOS drive number
        u8      Reserved;            // Reserved
        u8      BootSignature;       // Boot signature (0x29 if present)
        le u32  VolumeID;            // Volume ID (serial number)
        char    VolumeLabel[11];     // Volume label
        char    FileSystemType[8];   // File system type ("FAT12   ", "FAT16   ")
        char    BootCode[448];
        u16     Signature;           // Boot sector signature (0x55AA)

        FATStart = ReservedSectors * BytesPerSector;
        FATSize = SectorsPerFAT16 * BytesPerSector;

        rootDirStart = (ReservedSectors + (FATCount * SectorsPerFAT16)) * BytesPerSector;
        dataStart = rootDirStart + (RootEntryCount * 32);

        bytesPerCluster = SectorsPerCluster * BytesPerSector;
    };

    struct FATEntry {
        u8 content[FATSize];
    };
    
    struct FAT_DirectoryEntry {
        char      Name[8];               // File name
        char      Extension[3];          // File extension
        u8        Attributes;            // File attributes
        u8        Reserved;              // Reserved for Windows NT
        u8        CreateTimeTenth;       // Creation time (tenths of a second)
        le u16    CreateTime;            // Creation time (HH:MM:SS)
        le u16    CreateDate;            // Creation date (YYYY-MM-DD)
        le u16    LastAccessDate;        // Last access date
        u16       Unused;
        le u16    WriteTime;             // Last write time
        le u16    WriteDate;             // Last write date
        le u16    StartingCluster;
        le u32    FileSize;              // File size in bytes

        if (StartingCluster != 0) {
            try {
                char data[FileSize] @ dataStart + ((StartingCluster - 2) * bytesPerCluster);
            } catch {
                char data[1] @ dataStart + ((StartingCluster - 2) * bytesPerCluster);
            }
        }
    };

    // VFAT Long File Name (LFN) entry
    struct VFAT_LFNEntry {
        u8        SequenceNumber;        // Order number (0x40 if last entry)
        char16    Name1[5];              // First 5 characters
        u8        Attribute;             // Always 0x0F for LFN
        u8        Reserved;              // Always 0x00
        u8        Checksum;              // Checksum of short name
        char16    Name2[6];              // Next 6 characters
        le u16    FirstClusterZero;      // Must be 0
        char16    Name3[2];              // Last 2 characters
    };
}

FAT16::FAT_BootSector bootSect @ 0;
FAT16::FATEntry FATs[bootSect.FATCount] @ FATStart;
FAT16::FAT_DirectoryEntry root_entries[bootSect.RootEntryCount] @ rootDirStart;
