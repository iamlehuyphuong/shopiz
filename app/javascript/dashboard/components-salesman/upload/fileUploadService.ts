/**
 * @domain Salesman - File Upload Component
 * File Upload Service
 * Handles file upload functionality with progress tracking
 */

// Simulates a file upload with progress updates
export const uploadFileDemo = (
    file: File,
    onProgress: (progress: number) => void,
    onSuccess: (response: any) => void,
    onError: (error: Error) => void,
): { cancel: () => void } => {
    // Create a unique ID for this upload
    const uploadId = Math.random().toString(36).substring(2, 15);

    // For demo purposes, we'll simulate the upload with a timer
    let progress = 0;
    const interval = setInterval(() => {
        // Increment progress
        progress += Math.random() * 10;

        if (progress >= 100) {
            // Upload complete
            clearInterval(interval);
            progress = 100;
            onProgress(progress);

            // Simulate server response delay
            setTimeout(() => {
                onSuccess({
                    id: uploadId,
                    name: file.name,
                    size: file.size,
                    type: file.type,
                    url: URL.createObjectURL(file), // Create a local URL for the file
                });
            }, 500);
        } else {
            // Update progress
            onProgress(Math.min(Math.round(progress), 99));
        }
    }, 500); // Update every 500ms

    // Return a cancel function
    return {
        cancel: () => {
            clearInterval(interval);
            onError(new Error("Upload cancelled"));
        },
    };
};

// Format file size in KB or MB
export const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) {
        return bytes + " B";
    } else if (bytes < 1024 * 1024) {
        return (bytes / 1024).toFixed(0) + "KB";
    } else {
        return (bytes / (1024 * 1024)).toFixed(1) + "MB";
    }
};

// Validate file type and size
export const validateFile = (
    file: File,
    allowedTypes: string[],
    maxSize: number,
): { valid: boolean; message?: string } => {
    // Check file type
    const fileType = file.type.split("/")[1]?.toLowerCase();
    if (
        !allowedTypes.some(
            (type) => file.type.includes(type) || fileType === type.toLowerCase(),
        )
    ) {
        return {
            valid: false,
            message: `File type not supported. Please upload ${allowedTypes.join(", ")} files.`,
        };
    }

    // Check file size (maxSize in MB)
    if (file.size > maxSize * 1024 * 1024) {
        return {
            valid: false,
            message: `File too large. Maximum size is ${maxSize}MB.`,
        };
    }

    return { valid: true };
};
