import React, { useState } from "react";
import { Search, Filter, Bell } from "lucide-react";
import { getTheme } from "../Common/Theme";
import { tasks, categories } from "../Common/MockData";
import { CategoryId, Task } from "../Common/types";

interface HomeViewProps {
    onTaskSelect: (task: Task) => void;
    onShowNotifications: () => void;
    onShowFilters: () => void;
}

export const HomeView: React.FC<HomeViewProps> = ({ onTaskSelect, onShowNotifications, onShowFilters }) => {
    const isDarkMode = true;
    const theme = getTheme(isDarkMode);
    const [activeCategory, setActiveCategory] = useState<CategoryId>("all");
    const [searchQuery, setSearchQuery] = useState("");

    return (
        <div className="flex-1 flex flex-col h-full relative">
            <div
                className={`px-6 pb-5 pt-8 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} transition-all duration-500 z-30`}
            >
                <div className="flex justify-between items-center mb-6">
                    <div className="flex items-center gap-3">
                        <div className="w-[52px] h-[52px] rounded-[18px] bg-[#f3bb19] border-2 border-[#f4f3f1]/20 overflow-hidden relative shadow-lg">
                            <img 
                                src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=256&q=80" 
                                className="w-full h-full object-cover" 
                                alt="User" 
                            />
                        </div>
                        <div>
                            <p className="text-[13px] font-medium mb-0.5" style={{ color: theme.textSecondary }}>Good Morning 👋</p>
                            <h1 className="text-[20px] font-extrabold leading-none tracking-tight" style={{ color: theme.text }}>Sarah Miller</h1>
                        </div>
                    </div>
                    <button 
                        onClick={onShowNotifications}
                        className={`w-[46px] h-[46px] rounded-[16px] ${theme.cardBg} border ${theme.cardBorder} flex items-center justify-center relative hover:scale-[1.05] active:scale-95 transition-all shadow-sm`}
                    >
                        <Bell className="w-5 h-5" style={{ color: theme.text }} />
                        <span className="absolute top-3.5 right-3.5 w-2 h-2 bg-[#f49d9d] rounded-full border-2" style={{ borderColor: theme.phoneBg }} />
                    </button>
                </div>

                <div className="relative mb-3">
                    <Search
                    className="absolute left-[16px] top-1/2 -translate-y-1/2 w-4 h-4 transition-colors duration-500"
                    style={{ color: theme.textSecondary }}
                    strokeWidth={2.5}
                    />
                    <input
                    type="text"
                    placeholder="Search amazing projects..."
                    className={`w-full h-[48px] ${theme.inputBg} backdrop-blur-lg border-[1.5px] ${theme.inputBorder} rounded-[16px] pl-[44px] pr-[56px] text-[14px] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
                    style={{ color: theme.text }}
                    value={searchQuery}
                    onChange={(e) =>
                        setSearchQuery(e.target.value)
                    }
                    />
                    <button 
                    onClick={onShowFilters}
                    className="absolute right-1.5 top-1/2 -translate-y-1/2 bg-[#146068] rounded-[12px] w-[38px] h-[38px] flex items-center justify-center hover:scale-110 transition-transform shadow-lg active:scale-90"
                    >
                    <Filter
                        className="w-4 h-4 text-[#f4f3f1]"
                        strokeWidth={2.5}
                    />
                    </button>
                </div>

                <div
                    className="flex gap-2 overflow-x-auto pb-1"
                    style={{
                    scrollbarWidth: "none",
                    msOverflowStyle: "none",
                    }}
                >
                    {categories.map((cat) => (
                    <button
                        key={cat.id}
                        onClick={() =>
                        setActiveCategory(cat.id)
                        }
                        className={`px-4 py-2 rounded-[12px] text-[13px] font-semibold whitespace-nowrap transition-all duration-300 active:scale-95 ${
                        activeCategory === cat.id
                            ? "bg-[#146068] text-[#f4f3f1] shadow-lg"
                            : `${theme.inputBg} backdrop-blur-lg border ${theme.inputBorder} hover:bg-[#f4f3f1]/15`
                        }`}
                        style={
                        activeCategory !== cat.id
                            ? { color: theme.text }
                            : {}
                        }
                    >
                        {cat.label}
                    </button>
                    ))}
                </div>
            </div>

            <div
                className={`flex-1 overflow-y-auto px-6 py-5 bg-gradient-to-b ${theme.contentGradient} transition-all duration-500 pb-32`}
                style={{
                    scrollbarWidth: "thin",
                    scrollbarColor: theme.scrollbarColor,
                }}
            >
                <div className="space-y-4 pb-4">
                    {tasks.map((task) => (
                    <div
                        key={task.id}
                        className={`${theme.cardBg} backdrop-blur-2xl rounded-[20px] overflow-hidden border ${theme.cardBorder} hover:${theme.cardBorderHover} hover:-translate-y-2 hover:scale-[1.02] active:scale-[0.98] transition-all duration-500 cursor-pointer`}
                        onClick={() => onTaskSelect(task)}
                    >
                        <div className="h-32 relative" style={{ backgroundColor: task.bgColor }}>
                            <div className={`absolute inset-0 bg-gradient-to-t ${theme.taskGradient} to-transparent`} />
                            {task.isHot && <div className="absolute top-3 left-3 bg-[#f49d9d] text-[#f4f3f1] px-2.5 py-1 rounded-lg text-[10px] font-extrabold uppercase tracking-wide shadow-lg">🔥 HOT</div>}
                            <div className="absolute top-3 right-3"><span className={`px-3 py-1.5 rounded-lg text-[10px] font-extrabold uppercase tracking-wider backdrop-blur-lg border shadow-lg ${task.type === "Tender" ? "bg-[#f49d9d]/90 text-[#f4f3f1] border-[#f4f3f1]/30" : "bg-[#146068]/90 text-[#f4f3f1] border-[#93ccce]/30"}`}>{task.type}</span></div>
                        </div>
                        <div className="p-4 relative">
                            <h3 className="text-[16px] font-extrabold mb-2" style={{ color: theme.text }}>{task.title}</h3>
                            <p className="text-[13px] leading-relaxed mb-3" style={{ color: theme.textSecondary }}>{task.description}</p>
                            <div className={`flex justify-between items-center pt-3 border-t ${theme.cardBorder}`}>
                            <span className="text-[18px] font-black text-[#146068]">{task.budget}</span>
                            </div>
                        </div>
                    </div>
                    ))}
                </div>
            </div>
        </div>
    );
}