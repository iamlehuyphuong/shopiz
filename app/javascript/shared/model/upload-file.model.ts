export interface UploadItem {
    id: string;
    file: File;
    fileName: string;
    fileSize: string;
    progress: number;
    state: "uploading" | "uploaded" | "error";
    errorMessage?: string;
    uploadController?: { cancel: () => void };
}