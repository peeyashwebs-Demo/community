export type UserRole = "reader" | "writer" | "editor";
export type UserStatus = "active" | "suspended";
export type ArticleStatus = "draft" | "in_review" | "published" | "rejected";
export type CommentStatus = "visible" | "hidden" | "deleted";

export interface Profile {
  id: string;
  name: string;
  email: string;
  avatar_url: string | null;
  role: UserRole;
  status: UserStatus;
  created_at: string;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
}

export interface Tag {
  id: string;
  name: string;
}

export interface Article {
  id: string;
  title: string;
  slug: string;
  body: string; // HTML from Tiptap
  cover_image_url: string | null;
  status: ArticleStatus;
  author_id: string;
  category_id: string | null;
  read_count: number;
  like_count: number;
  review_note: string | null;
  published_at: string | null;
  created_at: string;
  updated_at: string;
  // joined (only present when selected with a relation)
  author?: Profile;
  category?: Category;
  tags?: Tag[];
}

export interface Comment {
  id: string;
  article_id: string;
  author_id: string;
  body: string;
  status: CommentStatus;
  created_at: string;
  author?: Profile;
}

export interface ReviewLog {
  id: string;
  article_id: string;
  editor_id: string;
  action: "approve" | "reject" | "request_changes";
  note: string | null;
  created_at: string;
}

export interface Like {
  article_id: string;
  user_id: string;
  created_at: string;
}

export interface Feedback {
  id: string;
  user_id: string | null;
  name: string;
  email: string | null;
  message: string;
  rating: number | null;
  status: "new" | "reviewed";
  created_at: string;
}

// Bare table shapes (no joined fields) — what Postgres actually stores per row.
type ArticleRow = Omit<Article, "author" | "category" | "tags">;
type CommentRow = Omit<Comment, "author">;
type ArticleTagRow = { article_id: string; tag_id: string };

// Generic helper so every table gets Row/Insert/Update, which is what
// supabase-js's PostgrestClient generics expect — without it, inference
// on .select()/.eq()/.update() can silently collapse to `never`.
type Table<Row> = {
  Row: Row;
  Insert: Partial<Row>;
  Update: Partial<Row>;
};

export interface Database {
  public: {
    Tables: {
      profiles: Table<Profile>;
      categories: Table<Category>;
      tags: Table<Tag>;
      articles: Table<ArticleRow>;
      article_tags: Table<ArticleTagRow>;
      comments: Table<CommentRow>;
      review_logs: Table<ReviewLog>;
      feedback: Table<Feedback>;
      likes: Table<Like>;
    };
    Views: {};
    Functions: {
      increment_read_count: {
        Args: { article_slug: string };
        Returns: undefined;
      };
      current_role: {
        Args: Record<PropertyKey, never>;
        Returns: UserRole;
      };
      claim_first_editor: {
        Args: Record<PropertyKey, never>;
        Returns: boolean;
      };
      toggle_like: {
        Args: { p_article_id: string };
        Returns: boolean;
      };
    };
    Enums: {};
    CompositeTypes: {};
  };
}
