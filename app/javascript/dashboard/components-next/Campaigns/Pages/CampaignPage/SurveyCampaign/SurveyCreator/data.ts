export interface SurveyElement {
    type: "dropdown" | "checkbox" | "radiogroup";
    name: string;
    title: string;
    description: string;
    choices?: string[];
    colCount?: number;
}

export interface SurveyJSON {
    elements: SurveyElement[];
}

export const surveyJSON: SurveyJSON = {
    elements: [
        {
            type: "dropdown",
            name: "cars",
            title: "Which is the brand of your car?",
            description:
                'Select "AI" -> "Generate choices by title" or "Generate more choices" to populate the question with automatically created choice options.',
        },
        {
            type: "dropdown",
            name: "grammar-errors",
            title: "Tihs queston contain gramar and sppeling erors",
            description:
                'Select "AI" -> "Fix grammar errors" to fix them automatically.',
            choices: ["Itme 1", "Ittem 2", "Imte 3"],
        },
        {
            type: "checkbox",
            name: "js-frameworks",
            title: "Which JavaScript frameworks do you use?",
            description:
                'Select "AI" -> "Generate choices by title" or "Generate more choices" to populate the question with automatically created choice options.',
            colCount: 2,
        },
        {
            type: "radiogroup",
            name: "product-discovery",
            title: "How did you first discover our product?",
            description:
                'Select "AI" -> "Generate choices by title" or "Generate more choices" to populate the question with automatically created choice options.',
        },
    ],
};