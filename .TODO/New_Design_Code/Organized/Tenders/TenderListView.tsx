import React from "react";
import { FileText } from "lucide-react";
import { getTheme } from "../Common/Theme";
import { tasks } from "../Common/MockData";
import { Task } from "../Common/types";

interface TenderListViewProps {
    onTaskSelect: (task: Task) => void;
}

export const TenderListView: React.FC<TenderListViewProps> = ({ onTaskSelect }) => {
    const isDarkMode = true;
    const theme = getTheme(isDarkMode);

    return (
        <div className="flex-1 flex flex-col h-full">
            <div className={`px-6 pb-5 pt-8 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} transition-all duration-500 z-30`}>
                <div className="flex justify-between items-center mb-4">
                    <div>
                    <h1
                        className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none transition-colors duration-500"
                        style={{ color: theme.text }}
                    >
                        Tenders
                    </h1>
                    <p
                        className="text-[13px] font-medium transition-colors duration-500"
                        style={{ color: theme.textSecondary }}
                    >
                        Open proposals & competitions
                    </p>
                    </div>
                    <div className="bg-[#f49d9d]/20 backdrop-blur-lg px-3 py-1.5 rounded-xl border border-[#f49d9d]/40">
                    <FileText
                        className="w-4 h-4 text-[#f49d9d]"
                        strokeWidth={2.5}
                    />
                    </div>
                </div>
            </div>

            <div
                className={`flex-1 overflow-y-auto px-6 py-5 bg-gradient-to-b ${theme.contentGradient} transition-all duration-500 pb-32`}
                style={{
                scrollbarWidth: "thin",
                scrollbarColor: theme.scrollbarColor,
                }}
            >
                <div className="space-y-3">
                    {tasks.filter(t => t.type === 'Tender').map(task => (
                        <div key={task.id} onClick={() => onTaskSelect(task)} className={`${theme.cardBg} backdrop-blur-lg rounded-[18px] p-4 border ${theme.cardBorder} relative overflow-hidden cursor-pointer active:scale-[0.98]`}>
                            <div className="flex items-start justify-between mb-3 relative">
                            <div className="flex items-center gap-2">
                            <div className="w-9 h-9 rounded-full flex items-center justify-center font-bold text-[14px] text-white" style={{ backgroundColor: task.bgColor }}>{task.author.initials}</div>
                            <div>
                                <div className="flex items-center gap-1">
                                <span className="text-[13px] font-bold" style={{ color: theme.text }}>{task.author.name}</span>
                                {task.author.verified && <span className="text-[12px]">✓</span>}
                                </div>
                                <span className="text-[10px] font-medium" style={{ color: theme.textSecondary }}>{task.author.time}</span>
                            </div>
                            </div>
                            <div className="bg-[#f49d9d]/20 px-2.5 py-1 rounded-lg flex items-center gap-1">
                            <FileText className="w-3 h-3 text-[#f49d9d]" strokeWidth={2.5} />
                            <span className="text-[10px] font-bold text-[#f49d9d]">TENDER</span>
                            </div>
                        </div>
                        <h3 className="text-[15px] font-extrabold mb-1.5" style={{ color: theme.text }}>{task.title}</h3>
                        <p className="text-[12px] mb-3 line-clamp-2" style={{ color: theme.textSecondary }}>{task.description}</p>
                        <div className="flex justify-between items-center pt-3 border-t" style={{ borderColor: theme.cardBorder }}>
                            <div className="flex items-center gap-3">
                                <span className="text-[11px] font-bold text-[#f49d9d]">{task.timeLeft}</span>
                                <span className="text-[11px] font-bold" style={{ color: theme.text }}>{task.offers || 0} offers</span>
                            </div>
                            <span className="text-[15px] font-extrabold text-[#146068]">{task.budget}</span>
                        </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};