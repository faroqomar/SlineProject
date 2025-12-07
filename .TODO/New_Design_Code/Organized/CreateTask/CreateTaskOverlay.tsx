import React, { useState } from "react";
import { X, ChevronLeft, ChevronRight } from "lucide-react";
import { getTheme } from "../Common/Theme";
import { popularCategories } from "../Common/MockData";
import { TaskFormState, ServiceTier } from "../Common/types";

interface CreateTaskOverlayProps {
    onClose: () => void;
}

export const CreateTaskOverlay: React.FC<CreateTaskOverlayProps> = ({ onClose }) => {
    const isDarkMode = true;
    const theme = getTheme(isDarkMode);
    const [createStep, setCreateStep] = useState(1);
    const [activePackageTab, setActivePackageTab] = useState<ServiceTier>("Basic");
    const [taskForm, setTaskForm] = useState<TaskFormState>({
        title: "",
        description: "",
        category: "design",
        budget: "",
        type: "Tender",
        tags: "",
        deadline: "7",
        experienceLevel: "Intermediate",
        packages: {
          Basic: { price: "", deliveryTime: "3", description: "", revisions: "1" },
          Standard: { price: "", deliveryTime: "7", description: "", revisions: "2" },
          Premium: { price: "", deliveryTime: "14", description: "", revisions: "Unlimited" }
        }
    });

    const handleClose = () => {
        onClose();
        setTimeout(() => setCreateStep(1), 300);
    };

    return (
        <div className="absolute inset-0 z-50 flex flex-col transition-colors duration-500 animate-slide-up" style={{ backgroundColor: theme.phoneBg }}>
            <div className={`px-6 pb-2 pt-8 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} transition-all duration-500 z-10`}>
                <div className="flex justify-between items-center mb-4">
                    <button onClick={handleClose}><X className="w-5 h-5 text-[#146068]" /></button>
                    <h1 className="text-[20px] font-extrabold" style={{ color: theme.text }}>Create Task</h1>
                </div>
                <div className="w-full bg-[#146068]/10 h-1.5 rounded-full overflow-hidden mb-2">
                    <div className="h-full bg-[#146068] transition-all duration-500" style={{ width: `${(createStep/3)*100}%` }} />
                </div>
                <div className="flex justify-between text-[11px] font-bold" style={{ color: theme.textSecondary }}>
                    <span className={createStep >= 1 ? "text-[#146068]" : ""}>Concept</span>
                    <span className={createStep >= 2 ? "text-[#146068]" : ""}>Details</span>
                    <span className={createStep >= 3 ? "text-[#146068]" : ""}>Logistics</span>
                </div>
            </div>

            <div className="flex-1 overflow-y-auto px-6 py-5 relative z-0">
                {createStep === 1 && (
                    <div className="space-y-6 animate-fade-in">
                    <div>
                        <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Select Task Type</h3>
                        <div className="grid grid-cols-2 gap-3">
                            <button onClick={() => setTaskForm({...taskForm, type: "Tender"})} className={`h-[100px] rounded-[18px] border-2 transition-all duration-300 hover:scale-[1.02] active:scale-95 ${taskForm.type === "Tender" ? "bg-[#f49d9d]/20 border-[#f49d9d]" : `${theme.cardBg} border-transparent`}`}>
                                <div className="flex flex-col items-center justify-center gap-2">
                                <span className="text-[28px]">📋</span>
                                <span className="text-[14px] font-bold" style={{ color: taskForm.type === "Tender" ? "#f49d9d" : theme.text }}>Tender</span>
                                <span className="text-[10px]" style={{ color: theme.textSecondary }}>Open proposals</span>
                                </div>
                            </button>
                            <button onClick={() => setTaskForm({...taskForm, type: "Booking"})} className={`h-[100px] rounded-[18px] border-2 transition-all duration-300 hover:scale-[1.02] active:scale-95 ${taskForm.type === "Booking" ? "bg-[#146068]/20 border-[#146068]" : `${theme.cardBg} border-transparent`}`}>
                                <div className="flex flex-col items-center justify-center gap-2">
                                <span className="text-[28px]"></span>
                                <span className="text-[14px] font-bold" style={{ color: taskForm.type === "Booking" ? "#146068" : theme.text }}>Booking</span>
                                <span className="text-[10px]" style={{ color: theme.textSecondary }}>Direct hire</span>
                                </div>
                            </button>
                        </div>
                    </div>
                    <div>
                        <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Choose Category</h3>
                        <div className="grid grid-cols-3 gap-2.5">
                            {popularCategories.map((cat, index) => (
                                <button key={index} onClick={() => setTaskForm({...taskForm, category: cat.name.toLowerCase()})} className={`h-[80px] rounded-[16px] border-2 transition-all duration-300 active:scale-95 ${taskForm.category !== cat.name.toLowerCase() ? `${theme.cardBg} border-transparent` : ""}`} style={{ backgroundColor: taskForm.category === cat.name.toLowerCase() ? `${cat.color}20` : undefined, borderColor: taskForm.category === cat.name.toLowerCase() ? cat.color : undefined }}>
                                <div className="flex flex-col items-center justify-center gap-1.5">
                                    <span className="text-[24px]">{cat.icon}</span>
                                    <span className="text-[11px] font-bold" style={{ color: theme.text }}>{cat.name}</span>
                                </div>
                                </button>
                            ))}
                        </div>
                    </div>
                    </div>
                )}

                {createStep === 2 && (
                    <div className="space-y-6 animate-fade-in">
                    <div>
                        <label className="text-[13px] font-bold mb-2 block" style={{ color: theme.text }}>Title</label>
                        <input type="text" placeholder="e.g., Modern Logo Design" value={taskForm.title} onChange={(e) => setTaskForm({...taskForm, title: e.target.value})} className={`w-full h-[52px] ${theme.inputBg} border ${theme.inputBorder} rounded-[14px] px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} />
                    </div>
                    <div>
                        <label className="text-[13px] font-bold mb-2 block" style={{ color: theme.text }}>Description</label>
                        <textarea placeholder="Describe your project..." value={taskForm.description} onChange={(e) => setTaskForm({...taskForm, description: e.target.value})} rows={5} className={`w-full ${theme.inputBg} border ${theme.inputBorder} rounded-[14px] p-4 outline-none resize-none focus:border-[#146068]`} style={{ color: theme.text }} />
                    </div>
                    <div>
                        <label className="text-[13px] font-bold mb-2 block" style={{ color: theme.text }}>Tags</label>
                        <input type="text" placeholder="e.g., Design, Logo (comma separated)" value={taskForm.tags} onChange={(e) => setTaskForm({...taskForm, tags: e.target.value})} className={`w-full h-[52px] ${theme.inputBg} border ${theme.inputBorder} rounded-[14px] px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} />
                    </div>
                    </div>
                )}

                {createStep === 3 && (
                    <div className="space-y-6 animate-fade-in">
                    {taskForm.type === 'Booking' ? (
                        <>
                            <div className={`p-1 rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} flex mb-2`}>
                                {(['Basic', 'Standard', 'Premium'] as ServiceTier[]).map(tier => (
                                <button key={tier} onClick={() => setActivePackageTab(tier)} className={`flex-1 py-2 rounded-[10px] text-[11px] font-bold transition-all duration-300 ${activePackageTab === tier ? 'bg-[#146068] text-white shadow-lg' : 'text-gray-400 hover:text-white'}`}>{tier}</button>
                                ))}
                            </div>
                            <div className="space-y-4">
                                <div className="flex gap-3">
                                <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Price ($)</label><input type="number" value={taskForm.packages[activePackageTab].price} onChange={e => setTaskForm({...taskForm, packages: {...taskForm.packages, [activePackageTab]: {...taskForm.packages[activePackageTab], price: e.target.value}}})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Delivery (Days)</label><input type="number" value={taskForm.packages[activePackageTab].deliveryTime} onChange={e => setTaskForm({...taskForm, packages: {...taskForm.packages, [activePackageTab]: {...taskForm.packages[activePackageTab], deliveryTime: e.target.value}}})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Revisions</label><input type="text" value={taskForm.packages[activePackageTab].revisions} onChange={e => setTaskForm({...taskForm, packages: {...taskForm.packages, [activePackageTab]: {...taskForm.packages[activePackageTab], revisions: e.target.value}}})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                </div>
                                <div><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Description</label><textarea value={taskForm.packages[activePackageTab].description} onChange={e => setTaskForm({...taskForm, packages: {...taskForm.packages, [activePackageTab]: {...taskForm.packages[activePackageTab], description: e.target.value}}})} className={`w-full h-[80px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} p-3 resize-none outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                            </div>
                        </>
                    ) : (
                        <>
                            <div><label className="text-[13px] font-bold mb-2 block" style={{ color: theme.text }}>Budget ($)</label><input type="number" value={taskForm.budget} onChange={e => setTaskForm({...taskForm, budget: e.target.value})} className={`w-full h-[52px] ${theme.inputBg} border ${theme.inputBorder} rounded-[14px] px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                            <div><label className="text-[13px] font-bold mb-3 block" style={{ color: theme.text }}>Deadline</label><div className="grid grid-cols-4 gap-2">{[{value:"3",label:"3 Days"},{value:"7",label:"1 Week"},{value:"14",label:"2 Weeks"},{value:"30",label:"1 Month"}].map(opt => (<button key={opt.value} onClick={() => setTaskForm({...taskForm, deadline: opt.value})} className={`h-[50px] rounded-[12px] border transition-all ${taskForm.deadline === opt.value ? "bg-[#146068]/20 border-[#146068] text-[#146068]" : `${theme.cardBg} border-transparent text-gray-500`}`}><span className="text-[12px] font-bold">{opt.label}</span></button>))}</div></div>
                        </>
                    )}
                    <div>
                        <label className="text-[13px] font-bold mb-3 block" style={{ color: theme.text }}>Experience Level</label>
                        <div className="grid grid-cols-3 gap-2">
                            {['Entry', 'Intermediate', 'Expert'].map(level => (
                                <button key={level} onClick={() => setTaskForm({...taskForm, experienceLevel: level as any})} className={`h-[50px] rounded-[12px] border transition-all ${taskForm.experienceLevel === level ? "bg-[#146068]/20 border-[#146068] text-[#146068]" : `${theme.cardBg} border-transparent text-gray-500`}`}>
                                <span className="text-[12px] font-bold">{level}</span>
                                </button>
                            ))}
                        </div>
                    </div>
                    </div>
                )}
            </div>

            <div className={`px-6 py-4 ${theme.bottomNavBg} backdrop-blur-2xl border-t ${theme.bottomNavBorder} flex gap-3 z-10`}>
                {createStep > 1 && <button onClick={() => setCreateStep(createStep - 1)} className={`w-[52px] h-[52px] rounded-[14px] ${theme.cardBg} border ${theme.cardBorder} flex items-center justify-center`}><ChevronLeft className="w-5 h-5" style={{ color: theme.text }} /></button>}
                <button onClick={() => createStep < 3 ? setCreateStep(createStep + 1) : handleClose()} className="flex-1 h-[52px] bg-[#146068] rounded-[14px] text-[15px] font-bold text-[#f4f3f1] hover:scale-[1.02] active:scale-95 transition-all shadow-xl flex items-center justify-center gap-2">
                    {createStep === 3 ? "Create Task" : "Next Step"}
                    {createStep < 3 && <ChevronRight className="w-5 h-5" />}
                </button>
            </div>
        </div>
    );
};